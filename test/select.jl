module TestSelect

using Relations
using Base.Test

a = [1, 2, 3]
b = [4, 5, 6]
c = ["a", "b", "c"]
d = [:a, :b, :c]

for T in (Array, NullableArray)
    global src = Relation(a=T(a), b=T(b), c=T(c), d=T(d))
    global _src = copy(src)

    for (field, col) in zip(Relations.attributes(src), Relations.columns(src))
        @eval res = @with src select($field)
        @eval _res = Relation($field = $T($col))
        @test isequal(src, _src)
        @test isequal(res, _res)
    end

    f = a .* b
    _res1 = Relation(f=T(f))
    res1 = @with src select(f = a * b)
    @test isequal(src, _src)
    @test isequal(res1, _res1)
end

# non-standard lifting semantics

# isnull(x)
src = Relation(
    a = NullableArray(collect(1:5), [true, false, true, false, true]))
_res = Relation(
    b = [true, false, true, false, true])

res = @with src select(b = isnull(a))
@test isequal(res, _res)

end
