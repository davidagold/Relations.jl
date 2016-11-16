# an abstract named tuple type
abstract Attributed

# as a tuple
Base.length(a::Attributed) = nfields(a)
Base.start(a::Attributed) = 1
Base.next(a::Attributed, s) = getfield(a, s), s+1
Base.done(a::Attributed, s) = s > length(fieldnames(a))
