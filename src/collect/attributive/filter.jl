function SQ._collect{R<:Relation}(_src::Tuple{R}, q::SQ.Node{SQ.Filter})
    src = first(_src)
    # @time res = similar(src)
    res = similar(src)
    d = first(SQ.dos(q))
    # @time grow!(res, src, d)
    grow!(res, src, d)
    return res
end

# function grow!{F}(res, src, f::F)::Void
function grow!{F}(res, src, d::SQ.Filter{F})::Void
    f = first(SQ.parts(d))::F
    for i in src
        v = f(i)
        if ifelse(isnull(v), false, unsafe_get(v))
            push!(res, i)
        end
    end
end
