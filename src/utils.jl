# We provide @generated implementations that unroll over Tuples/Attributeds

@generated function ith_all(i, a::Attributed)
    Expr(:block, :(@Base._inline_meta),
         Expr(:tuple,
              [ Expr(:ref, Expr(:., :a, Expr(:quote, fieldname(a,j))), :i) for j = 1:nfields(a) ]...))
end

@generated function foreach(f, a::Attributed)
    Expr(:block,
         [ Expr(:call, :f, Expr(:., :a, Expr(:quote, fieldname(a,j)))) for j = 1:nfields(a) ]...)
end

@generated function foreach(f, c::Union{Tuple,Attributed}, v::Union{Tuple,Attributed})
    Expr(:block,
         [ Expr(:call, :f,
                Expr(:call, :getfield, :c, j),
                Expr(:call, :getfield, :v, j)) for j = 1:nfields(c) ]...)
end

SQ.name(::Type{Relation}) = "Relation"
