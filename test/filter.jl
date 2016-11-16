module TestFilter

using Relations
using Base.Test

A = [1, 2, 3]
B = [4, 5, 6]
C = ["a", "b", "c"]
D = [:a, :b, :c]

for T in (Array, NullableArray)
    src = Relation(A=T(A), B=T(B), C=T(C), D=T(D))
    _src = copy(src)

    # basic functionality

    I = find(i->i>2, A)
    _res = Relation(A=T(A[I]), B=T(B[I]), C=T(C[I]), D=T(D[I]))
    res = @with src filter(A > 2)
    @test isequal(src, _src)
    @test isequal(res, _res)
end

# non-standard lifting semantics

# three-valued logic semantics for |
src = Relation(
    A = NullableArray([true, true, false, false]),
    B = NullableArray([false, false, true, true], [true, false, true, false])
)
_src = copy(src)
_res = Relation(
    A = NullableArray([true, true, false]),
    B = NullableArray([false, false, true], [true, false, false])
)
res = @with src filter(A | B)
@test isequal(src, _src)
@test isequal(res, _res)

# three-valued logic semantics for &
src = Relation(
    A = NullableArray([true, true, false, false]),
    B = NullableArray([true, true, false, false], [true, false, true, false])
)
_src = copy(src)

_res = Relation(
    A = NullableArray([true]),
    B = NullableArray([true], [false])
)
res = @with src filter(A & B)
@test isequal(src, _src)
@test isequal(res, _res)

# isnull(x)

A = NullableArray([true, true, false, false])
B = NullableArray([true, true, false, false], [true, false, true, false])
src = Relation(A=A, B=B)
_src = copy(src)

I = find(i->isnull(i), A)
_res = Relation(A=A[I], B=B[I])
res = @with src filter(isnull(A))
@test isequal(src, _src)
@test isequal(res, _res)

I = find(i->isnull(i), B)
_res = Relation(A=A[I], B=B[I])
res = @with src filter(isnull(B))
@test isequal(src, _src)
@test isequal(res, _res)


end
