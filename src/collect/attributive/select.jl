SQ._collect{R<:Relation}(_src::Tuple{R}, q::SQ.Node{SQ.Select}) =
    Relations._collect(first(_src), q)

function pre_apply{S<:Attributed,T}(r::Relation{S,T}, q::SQ.Node{SQ.Select})
    _cols = Vector{Any}()
    _attrs = [ d.res_field for d in SQ.dos(q) ]
    fs = [ d.f for d in SQ.dos(q) ]
    nrow = length(r)
    for f in fs
        U = Core.Inference.return_type(f, Tuple{T})
        if isleaftype(U)
            U <: Nullable ? push!(_cols, NullableArray{eltype(U)}(nrow)) :
                            push!(_cols, Array{U}(nrow))
        # else TODO: make this a real code path for when inferred type is non-concrete
        end
    end
    return _cols, _attrs, fs
end

function _collect{S<:Attributed,T}(src::Relation{S,T}, q::SQ.Node{SQ.Select})
    # @time _cols, _attrs, fs = pre_apply(q, T)
    # @time res = Relation(_cols, _attrs)
    # @time apply!(res, tuple(fs...), src)
    _cols, _attrs, fs = pre_apply(src, q)
    res = Relation(tuple(_attrs...), _cols...)
    apply!(res, tuple(fs...), src)
    return res
end

@generated function apply!(res, fs, src)
    n = length(fs.parameters)
    v_exs, setindex!_exs = Expr(:block), Expr(:block)
    for j in 1:n
        push!(v_exs.args,
              Expr(:(=), Symbol("v_$j"),
              Expr(:call, Expr(:call, :getfield, :fs, j), :row)))
        push!(setindex!_exs.args,
              Expr(:call, :setindex!,
                   Expr(:call, :getfield, :(res.src), j), Symbol("v_$j"), :i))
    end
    res = quote
        for (i, row) in enumerate(src)
            $v_exs; $setindex!_exs
        end
        return
    end
end
