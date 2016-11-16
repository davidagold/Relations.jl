function SQ._collect{R<:Relation}(_src::Tuple{R}, q::SQ.Node{SQ.Summarize})
    src = first(_src)
    # TODO: figure out what happens if any columns in _res are empty (i.e.
    #       transformation of original columns produced no non-null values)
    res, gs, _res = pre_apply(src, q)
    grow_summaries!(res, gs, _res)
    return res
end

function pre_apply{S<:Attributed,T}(src::Relation{S,T}, q::SQ.Node{SQ.Summarize})
    _cols = Vector{Any}()
    fs = [ d.f for d in SQ.dos(q) ]
    _attrs = [ d.res_field for d in SQ.dos(q) ]
    nrow = length(src)
    for f in fs
        U = Core.Inference.return_type(f, Tuple{T})
        if isleaftype(U)
            U <: Nullable ? push!(_cols, Array{eltype(U)}(nrow)) :
                            push!(_cols, Array{U}(nrow))
        # else TODO: make this a real code path for when inferred type is non-concrete
        end
    end
    _res = Relation(tuple(_attrs...), _cols...)
    grow_nonnull!(_res, tuple(fs...), src)
    cols = Vector{Any}()
    attrs = Relations.attributes(_res)
    gs = tuple([ d.g for d in SQ.dos(q) ]...)
    for (j, g) in enumerate(gs)
        U = Core.Inference.return_type(g, Tuple{typeof(getfield(_res.src, j))})
        if isleaftype(U)
            push!(cols, Vector{U}())
        # else # TODO: make this a real code path
        end
    end
    res = Relation(tuple(attrs...), cols...)
    return res, gs, _res
end

# gs are aggregating functions
@generated function grow_summaries!(res, gs, _res)
    n = length(gs.parameters) # number of summarizations
    v_exs, push!_exs = Expr(:block), Expr(:block)
    for j in 1:n
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$j"),
              Expr(:call, Expr(:call, :getfield, :gs, j),
                   Expr(:call, :getfield, :(_res.src), j))))
        push!(push!_exs.args,
              Expr(:call, :push!,
                   Expr(:call, :getfield, :(res.src), j), Symbol("v_$j")))
    end
    return quote
        $v_exs; $push!_exs
    end
end

@generated function grow_nonnull!(res, fs, src)
    n = length(fs.parameters)
    v_exs, setindex!_exs = Expr(:block), Expr(:block)
    for j in 1:n
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$j"),
              Expr(:call, Expr(:call, :getfield, :fs, j), :row)))
        push!(setindex!_exs.args,
              Expr(:if, Expr(:call, :!, Expr(:call, :isnull, Symbol("v_$j"))),
                   Expr(:call, :setindex!,
                        Expr(:call, :getfield, :(res.src), j),
                             Symbol("v_$j"), :i)))
    end
    return quote
        for (i, row) in enumerate(src)
            $v_exs; $setindex!_exs
        end
        return
    end
end
