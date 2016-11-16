# an abstract named tuple type
abstract Attributed

# as a tuple
Base.length(a::Attributed) = nfields(a)
Base.start(a::Attributed) = 1
Base.next(a::Attributed, s) = getfield(a, s), s+1
Base.done(a::Attributed, s) = s > length(fieldnames(a))

function Base.isequal{A<:Attributed}(a1::A, a2::A)
    for (el1, el2) in zip(a1,a2)
        isequal(el1, el2) || return false
    end
    return true
end

function Base.hash(a::Attributed, h::UInt)
    for el in a
        h = hash(el, h)
    end
    return h
end

Base.show(io::IO, a::Attributed) = Base.show_delim_array(io, a, '(', ',', ')', true)
