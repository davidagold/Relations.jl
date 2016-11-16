immutable Relation{S,T} <: AbstractVector{T}
    src::S
end

# map from tuples of attributes (as Symbols) to respective Attributed leaf type
let type_cache = Dict{Tuple{Vararg{Symbol}}, DataType}()
    global Relation
    function Relation{T<:Attributed}(::Type{T}, cols::AbstractVector...)::Relation
        A = type_cache[tuple(fieldnames(T)...)] # This key has to exist
        S = A{map(typeof, cols)...}
        return Relation{S,T}(S(cols...))
    end

    function Relation(; kwargs...)
        n = length(kwargs)
        attrs, cols = Vector{Symbol}(n), Vector{Any}(n)
        for (j,kwarg) in enumerate(kwargs)
            attrs[j]=kwarg[1]; cols[j]=kwarg[2];
        end
        return Relation(tuple(attrs...), cols...)
    end

    # function Relation(cols::Union{Vector{AbstractVector}, Tuple{Vararg{AbstractVector}}},
    function Relation(attrs::Tuple{Vararg{Symbol}}, cols::AbstractVector...)::Relation
        length(attrs) == length(cols) || throw(ArgumentError("Attributes, columns must be same length."))
        # We use @get! so that we only run eval if type_cache has no key attrs
        A = Base.@get! type_cache attrs begin
            _T = gensym()
            type_name_ex = Expr(:curly, _T)
            type_decl_ex = Expr(:(<:), type_name_ex, :Attributed)
            type_fields_ex = Expr(:block)
            for attr in attrs
                param = gensym()
                push!(type_name_ex.args, param)
                push!(type_fields_ex.args, Expr(:(::), attr, param))
            end
            typedef_ex = Expr(:type, false, type_decl_ex, type_fields_ex)
            # NOTE: uses of eval!
            eval(Relations, typedef_ex)
            eval(Relations, _T)
        end
        S, T = A{map(typeof, cols)...}, A{map(eltype, cols)...}
        return Relation{S,T}(S(cols...))
    end
end

Relation{T}(a::Attributed, ::Type{T}) = Relation{typeof(a),T}(a)

# as an iterator
Base.eltype{S,T}(r::Relation{S,T}) = T
Base.ndims{A<:Attributed}(r::Relation{A}) = 1

# as a container
Base.empty!(r::Relation) = (foreach(empty!, r.src); r)
Base.similar{S<:Attributed,T}(r::Relation{S,T}) = empty!(Relation(T, map(similar, r.src)...))
Base.similar{S<:Attributed,T}(r::Relation{S,T}, n::Integer) = Relation(T, map(c->similar(c,n), r.src)...)
Base.copy{S<:Attributed,T}(r::Relation{S,T}) = Relation{S,T}(S(map(copy, r.src)...))

# as an array
Base.size{A<:Attributed}(r::Relation{A}) = (length(r),)

# as a vector
Base.getindex{A<:Attributed,T}(r::Relation{A,T}, i) = T(ith_all(i, r.src)...)
Base.push!{A<:Attributed}(r::Relation{A}, v) = (foreach(push!, r.src, v))
Base.linearindexing{A<:Attributed}(r::Relation{A}) = Base.LinearFast()
# NOTE: not all sources will support length
Base.length{A<:Attributed}(r::Relation{A}) = length(first(r.src))

# as a bundle of vectors (NOTE: not all sources will support this)
columns{S<:Attributed}(r::Relation{S}) = r.src

# as a relation
function attributes end
function index end
attributes{S,T}(r::Relation{S,T}) = fieldnames(T)
function index{S,T}(r::Relation{S,T})::Dict{Symbol, Int}
    index = Dict{Symbol, Int}()
    for (j, attr) in enumerate(fieldnames(T))
        index[attr] = j
    end
    return index
end
project{S<:Attributed}(r::Relation{S}, attrs::Symbol...) =
    Relation(attrs, [ getfield(r.src, attr) for attr in attrs ]...)

function together{S1<:Attributed,S2<:Attributed}(r1::Relation{S1}, r2::Relation{S2})
    attrs1, attrs2 = attributes(r1), attributes(r2)
    attrs = vcat(attrs1, attrs2)
    cols = vcat([ getfield(r1.src, attr) for attr in attrs1 ],
                [ getfield(r2.src, attr) for attr in attrs2 ])
    return Relation(tuple(attrs...), cols...)
end

# as queryable
SQ.prepare{S<:Attributed}(r::Relation{S}) = r
SQ._with{S<:Attributed}(q::SQ.Node, ::Tuple{Relation{S}}) = collect(q)
SQ._with{S<:Attributed, T<:Attributed}(q::SQ.Node, ::Tuple{Relation{S}, Relation{T}}) = collect(q)

SQ.as{S<:Attributed}(r::Relation{S}, ::Type{Relation}) = r
SQ.as{S<:Attributed}(g::Grouped{Relation{S}}, ::Type{Relation}) = g
