# Adapted from
# https://github.com/JuliaData/AbstractTables.jl/blob/e5afc569504ecf08ec769fd52a78da4027eab35f/src/AbstractTable/show.jl

let
    local io = IOBuffer(Array(UInt8, 80), true, true)
    global ourstrwidth
    function ourstrwidth(x::Any)::Int
        truncate(io, 0)
        ourshowcompact(io, x)
        return position(io)
    end
    ourstrwidth(x::AbstractString) = strwidth(x) + 2 # -> Int
    # myconv = VERSION < v"0.4-" ? convert : Base.unsafe_convert
    ourstrwidth(s::Symbol) =
        @compat Int(
            ccall(:u8_strwidth, Csize_t, (Ptr{UInt8}, ),
            Base.unsafe_convert(Ptr{UInt8}, s))
        )
end

ourshowcompact(io::IO, x::Any)::Void = showcompact(io, x)
ourshowcompact(io::IO, x::AbstractString)::Void = showcompact(io, x)
ourshowcompact(io::IO, x::Symbol)::Void = print(io, x)

function getmaxwidths(r::Relation, rowlabel, limit, offset)::Vector{Int}
    attrs = attributes(r)
    ncols = length(attrs)
    widths = [ Vector{Int}() for j in 1:ncols ]
    maxwidths = Array{Int}(ncols + 1)
    undefstrwidth = ourstrwidth(Base.undef_ref_str)

    s = start(r)
    i = 1
    while (i <= offset) & (!done(r, s)) # skip through rows up to offset
        row, s = next(r, s)
        i += 1
    end
    while (i <= offset + limit) & (!done(r, s)) #
        row, s = next(r, s)
        for (j, v) in enumerate(row)
            try
                push!(widths[j], ourstrwidth(v))
            catch
                push!(widths[j], undefstrwidth)
            end
        end
        i += 1
    end
    for j in 1:ncols
        if isempty(widths[j]) # no rows
            maxwidths[j] = ourstrwidth(attrs[j])
        else # max width in column is max of max width of printed el and attribute width
            maxwidths[j] = max(maximum(widths[j]), ourstrwidth(attrs[j]))
        end
    end
    maxwidths[end] = max(ourstrwidth(rowlabel), ndigits(limit)+1)
    return maxwidths
end

function getprintedwidth(maxwidths::Vector{Int})::Int
    # Include length of line-initial |
    totalwidth = 1
    for i in 1:length(maxwidths)
        # Include length of field + 2 spaces + trailing |
        totalwidth += maxwidths[i] + 3
    end
    return totalwidth
end

pad(io, padding)::Void = print(io, " "^padding)

function print_bounding_line(io, maxwidths, j_left, j_right)::Void
    rowmaxwidth = maxwidths[end]
    print(io, '├', "─"^(rowmaxwidth + 2), '┼')
    for j in j_left:j_right
        print(io, "─"^(maxwidths[j] + 2))
        if j < j_right
            print(io, '┼')
        else
            print(io, '┤')
        end
    end
    print(io, '\n')
end

# NOTE: returns a Bool indicating whether or not there are more rows than what
# has printed
function print_rows(
  io, r, maxwidths, j_left, j_right, rowlabel, limit, offset)::Bool ##
    rowmaxwidth = maxwidths[end]
    attrs = attributes(r)
    p = project(r, attrs[j_left:j_right]...)
    s, i = start(p), 1
    while (i <= offset) & (!done(p, s)) # skip through offset
        row, s = next(p, s)
        i += 1
    end
    while (i <= offset + limit) & (!done(p, s))
        row, s = next(p, s)
        @printf(io, "│ %d", i)
        pad(io, rowmaxwidth - ndigits(i))
        # print(io, " │ ")
        print(io, "   ")
        # print entry
        for j in j_left:j_right
            v = getfield(row, j)
            strlen = ourstrwidth(v)
            ourshowcompact(io, v)
            pad(io, maxwidths[j] - strlen)
            if j == j_right
                if i == (limit+offset)
                    # print(io, " │")
                    print(io, "  ")
                else
                    # print(io, " │\n")
                    print(io, "  \n")
                end
            else
                print(io, "   ")
            end
        end
        i += 1
    end
    return (i > (limit+offset)) & (!done(p, s))
end

function print_footer(io, r, more_rows, j_right, limit, offset)::Void
    println(io, "\n⋮")
    attrs = attributes(r)
    ncols = length(attrs)
    if j_right < ncols
        @printf(io, "with more rows and %d more columns: ", ncols - j_right)
        for j in j_right+1:(ncol-1)
            attr = attrs[j]
            print(io, "$attr, ")
        end
        print(io, "$attr.")
    else
        print(io, "with more rows.")
    end
end

function print_footer{S<:Attributed}(
  io, r::Relation{S}, more_rows, j_right, limit, offset)::Void
    attrs = attributes(r)
    ncols, nrows = length(attrs), length(r)
    if more_rows
        println(io, "\n⋮")
        if j_right < ncols
            if offset > 0
                @printf(io, "with %d more rows (skipped the first %d rows) and %d more columns: ",
                        nrows-(limit+offset), offset, ncols-j_right)
            else
                @printf(io, "with %d more rows and %d more columns: ",
                        nrows-limit, ncols-j_right)
            end
            for j in j_right+1:(ncols-1)
                attr = attrs[j]; print(io, "$attr, ")
            end
            attr = attrs[ncols]; print(io, "$attr.")
        else
            if offset > 0
                @printf(io, "with %d more rows (skipped the first %d rows).",
                        nrows-(limit+offset), offset)
            else
                @printf(io, "with %d more rows.", nrows-limit)
            end
        end
    else
        if j_right < ncols
            println(io, "\n⋮")
            @printf(io, "with %d more columns: ", ncols-j_right)
            for j in j_right+1:(ncols-1)
                attr = attrs[j]
                print(io, "$attr, ")
            end
            attr = attrs[ncols]
            print(io, "$attr.")
        end
    end
    return
end

function print_header(io, r, maxwidths, j_left, j_right, rowlabel)::Void
    rowmaxwidth = maxwidths[end]
    attrs = attributes(r)
    @printf(io, "│ %s", rowlabel)
    pad(io, rowmaxwidth - ourstrwidth(rowlabel))
    # print(io, " │ ")
    print(io, "   ")
    for j in j_left:j_right
        attr = attrs[j]
        ourshowcompact(io, attr)
        pad(io, maxwidths[j] - ourstrwidth(attr))
        # j == j_right ? print(io, " │\n") : print(io, " │ ")
        j == j_right ? print(io, "  \n") : print(io, "   ")
    end
    print_bounding_line(io, maxwidths, j_left, j_right)
    return
end

function getchunkbounds(
  io, maxwidths::Vector{Int}, splitchunks::Bool,
  availablewidth::Int=displaysize(io)[2])::Vector{Int}
    ncols = length(maxwidths) - 1
    rowmaxwidth = maxwidths[end]
    if splitchunks
        chunkbounds = [0]
        # Include 2 spaces + 2 | characters for row/col label
        totalwidth = rowmaxwidth + 4
        for j in 1:ncols
            # Include 2 spaces + | character in per-column character count
            totalwidth += maxwidths[j] + 3
            if totalwidth > availablewidth
                push!(chunkbounds, j - 1)
                totalwidth = rowmaxwidth + 4 + maxwidths[j] + 3
            end
        end
        push!(chunkbounds, ncols)
    else
        chunkbounds = [0, ncols]
    end
    return chunkbounds
end

# 1 space for line-initial | + length of field + 2 spaces + trailing |
printedwidth(maxwidths)::Void = foldl((x,y)->x+y+3, 1, maxwidths)

function _show{S<:Attributed}(
  io, r::Relation{S}, rowlabel=Symbol("#"), displaysummary=true,
  splitchunks=true, allchunks=false, limit=10, offset=0)::Void ##
    ncols = length(attributes(r))
    if ncols > 0
        displaysummary && println(io, summary(r))
        # println("⋮")
        maxwidths = getmaxwidths(r, rowlabel, limit, offset)
        chunkbounds = getchunkbounds(io, maxwidths, splitchunks | !allchunks)
        if !allchunks # show only the first chunk
            j_left, j_right = 1, chunkbounds[2]
            print_header(io, r, maxwidths, j_left, j_right, rowlabel)
            more_rows = print_rows(
                io, r, maxwidths, j_left, j_right, rowlabel, limit, offset)
            print_footer(
                io, r, more_rows, j_right, limit, offset)
        else
            nchunks = length(chunkbounds) - 1
            more_rows = false
            for r in 1:nchunks
                j_left = chunkbounds[r] + 1
                j_right = chunkbounds[r + 1]
                print_tbl_header(io, r, maxwidths, j_left, j_right, rowlabel)
                more_rows |= print_rows(
                    io, r, maxwidths, j_left, j_right, rowlabel, limit, offset)
            end
            print_footer(
                io, r, more_rows, false, limit, offset)
        end
    else
        @printf(io, "An empty %s", typeof(tbl))
    end
    return
end

Base.summary(r::Relation) =
    @sprintf("Relation (source of type %s)", typeof(r.src))
Base.summary{S<:Attributed}(r::Relation{S}) = "Relation (in-memory Julia source)"
Base.show(io::IO, r::Relation) = _show(io, r)
Base.show(io::IO, ::MIME"text/plain", r::Relation) = _show(io, r)
Base.show(r::Relation; limit=10, offset=0) =
    _show(STDOUT, r, Symbol("#"), true, true, false, limit, offset)
# _show(r::Relation, limit, offset)::Void = _show(STDOUT, tbl, :Row, true, limit, offset)
