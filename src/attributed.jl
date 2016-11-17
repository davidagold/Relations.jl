# an abstract named tuple type
abstract Attributed

# as a tuple
Base.length(a::Attributed) = nfields(a)
Base.start(a::Attributed) = 1
Base.next(a::Attributed, s) = getfield(a, s), s+1
Base.done(a::Attributed, s) = s > nfields(a)

function Base.isequal{A<:Attributed}(a1::A, a2::A)
    for (el1, el2) in zip(a1,a2)
        isequal(el1, el2) || return false
    end
    return true
end

const attributedhash_seed = UInt === UInt64 ? 0x8d02b517474715f1 : 0xf5e5be51
@generated function Base.hash{A<:Attributed}(a::A, h::UInt)
    tuple_ex = Expr(:tuple)
    for j in 1:length(A.parameters)
        push!(tuple_ex.args, Expr(:call, :getfield, :a, j))
    end
    return quote
        $(Expr(:meta, :inline))
        hash($tuple_ex, hash(h, attributedhash_seed))
    end
end

Base.show(io::IO, a::Attributed) = Base.show_delim_array(io, a, '(', ',', ')', true)
