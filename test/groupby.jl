module TestGroupBy

using Relations
using Base.Test

name = ["Niamh", "Roger", "Genevieve", "Aiden"]
age = [27, 63, 26, 17]
eye_color = ["green", "brown", "brown", "blue"]

n = rand(10:1000)
A = rand(n)
B = rand(n)
C = rand(1:30, n)

for T in (Array, NullableArray)
    people = Relation(name = T(name), age = T(age), eye_color = T(eye_color))
    _people = copy(people)
    res = @with people groupby(eye_color, age > 26)
    @test isequal(people, _people)
    for level in res.group_levels
        for i in res.group_indices[level]
            row = res.src[i]
            for attr in fieldnames(level)
                @test isequal(getfield(row, attr), getfield(level, attr))
            end
        end
    end
    # TODO: Replace this test with something appropriate
    # @test isequal(res.groupbys, q.graph.args)

    src = Relation(A=T(A), B=T(B), C=T(C))
    _src = copy(src)
    res = @with src groupby(A > B, log(A+1) > log(A)+1, C)
    for level in res.group_levels
        for i in res.group_indices[level]
            row = res.src[i]
            for attr in fieldnames(level)
                @test isequal(getfield(row, attr), getfield(level, attr))
            end
        end
    end
end

end
