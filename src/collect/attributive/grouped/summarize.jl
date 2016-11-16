SQ._collect{R<:Relation}(_src::Tuple{Grouped{R}}, q::SQ.Node{SQ.Summarize}) =
    Relations._collect(first(_src), first(_src).src, q)

function _collect{R<:Relation,S<:Attributed,T}(gr::Grouped{R}, src::Relation{S,T}, q::SQ.Node{SQ.Summarize})
    res, fs, gs, _res = pre_apply(gr, q)
    grp_levels, grp_indices = gr.group_levels, gr.group_indices
    for level in grp_levels
        empty!(_res)
        indices = grp_indices[level]
        grow_nonnull!(_res, fs, src, indices)
        grow_summaries!(res, gs, _res, level)
    end
    return res
end

function pre_apply(gr::Grouped, q::SQ.Node{SQ.Summarize})
    _cols = Vector{Any}()
    _attrs = [ d.res_field for d in SQ.dos(q) ]
    fs = tuple([ d.f for d in SQ.dos(q) ]...)
    nrow = length(gr.src)
    T = typeof(gr.src).parameters[2]
    for f in fs
        U = Core.Inference.return_type(f, Tuple{T})
        if isleaftype(U)
            U <: Nullable ? push!(_cols, Vector{eltype(U)}()) :
                            push!(_cols, Vector{U}())
        # else TODO: make this a real code path for when inferred type is non-concrete
        end
    end
    _res = Relation(tuple(_attrs...), _cols...)
    # attributes, columns of res include groupbys and summaries
    cols = Any[ similar(getfield(gr.src.src, groupby), 0) for groupby in gr.groupbys ]
    attrs = tuple(vcat(gr.groupbys, _attrs)...)
    gs = tuple([ d.g for d in SQ.dos(q) ]...)
    for (_attr,g) in zip(_attrs, gs)
        U = Core.Inference.return_type(g, Tuple{typeof(getfield(_res.src, _attr))})
        if isleaftype(U)
            push!(cols, Vector{U}())
        else # TODO: make this a real code path
            error()
        end
    end
    res = Relation(attrs, cols...)
    return res, fs, gs, _res
end

# gs are aggregating functions
@generated function grow_summaries!(res, gs, _res, level)
    m = length(level.parameters) # number of groupbys
    n = length(gs.parameters) # number of summarizations
    v_exs, push!_exs = Expr(:block), Expr(:block)
    for j in 1:m
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$j"), Expr(:call, :getfield, :level, j)))
        push!(push!_exs.args,
              Expr(:call, :push!,
                   Expr(:call, :getfield, :(res.src), j), Symbol("v_$j")))
    end
    for j in 1:n
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$(j+m)"),
              Expr(:call, Expr(:call, :getfield, :gs, j),
                   Expr(:call, :getfield, :(_res.src), j))))
        push!(push!_exs.args,
              Expr(:call, :push!,
                   Expr(:call, :getfield, :(res.src), j+m), Symbol("v_$(j+m)")))
    end
    return quote
        $v_exs; $push!_exs
    end
end

@generated function grow_nonnull!(_res, fs, src, indices)
    n = length(fs.parameters)
    v_exs, push!_exs = Expr(:block), Expr(:block)
    for j in 1:n
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$j"),
              Expr(:call, Expr(:call, :getfield, :fs, j), :row)))
        # NOTE: This may result in a Relation with unequal-length columns!!
        #       Should really be a "Pseudo-Relation"
        push!(push!_exs.args,
              Expr(:if, Expr(:call, :!, Expr(:call, :isnull, Symbol("v_$j"))),
                   Expr(:call, :push!,
                        Expr(:call, :getfield, :(_res.src), j),
                             Expr(:call, :unsafe_get, Symbol("v_$j")))))
    end
    return quote
        for row in src[indices]
            $v_exs; $push!_exs
        end
        return
    end
end
