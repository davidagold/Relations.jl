SQ._collect{R<:Relation}(_src::Tuple{R}, q::SQ.Node{SQ.GroupBy}) =
    Relations._collect(first(_src), q)

function _collect{S<:Attributed}(_src::Relation{S}, q::SQ.Node{SQ.GroupBy})
    # Make a copy, don't mutate
    src = copy(_src)
    # Map from predicates (e.g. `A > .5`) to aliasing column names (e.g. `pred_1`)
    predicates = Dict{Symbol, Expr}()
    # pre_groupby!(src, q, predicates)
    new_src, groupbys = pre_groupby!(src, q, predicates)
    return groupby(new_src, groupbys, predicates)
end

function pre_groupby!{S<:Attributed}(src::Relation{S}, q, predicates)#::Tuple{Relation, Vector{Symbol}}
    _groupbys = copy(q.args)
    groupbys = Vector{Symbol}(length(_groupbys))
    dos = Vector{SQ.Select}()
    i = 1 # count number of predicates encountered
    println("for loop")
    @time for (d, (j, groupby)) in zip(q.dos, enumerate(_groupbys))
        if is_predicate
            alias = Symbol("pred_$i")
            predicates[alias] = groupby
            groupbys[j] = alias
            # include the result of applying the predicate as a new column
            push!(dos, SQ.Select(alias, f, ai))
            i += 1
        else
            if isa(groupby, Expr) && groupby.head == :.
                groupbys[j] = groupby.args[2].args[1]
            elseif isa(groupby, Symbol)
                groupbys[j] = groupby
            end
        end
    end

    println("pred_cols")
    @time pred_cols = _collect(src, SQ.Node{SQ.Select}((SQ.DataNode(src),), [], dos))
    new_src = together(src, pred_cols)

    return new_src, groupbys
end

function groupby{S<:Attributed}(src::Relation{S}, groupbys, predicates)::SQ.Grouped
    metadata = Dict{Symbol, Any}()
    metadata[:predicates] = predicates
    # obtain the field names of the groupbys (either the names of the selected
    # columns or the predicate aliases given to groupby predicates)
    println("build_group_data")
    group_indices, group_levels = @time build_group_data(src, groupbys)
    return SQ.Grouped(src, group_indices, groupbys, group_levels, metadata)
end

function build_group_data(src, groupbys)
    p = project(src, groupbys...)
    group_indices = Dict{typeof(p).parameters[2], Vector{Int}}()
    println("grow_indices")
    group_levels = @time grow_indices!(group_indices, p)
    return group_indices, group_levels
end

@noinline function grow_indices!{S,T}(group_indices, src::Relation{S,T})::Vector{T}
    group_levels = Vector{T}()
    for (i, row) in enumerate(src) # the row is the group level
        if haskey(group_indices, row)
            push!(group_indices[row], i)
        else
            group_indices[row] = [i]
            push!(group_levels, row)
        end
    end
    return group_levels
end
