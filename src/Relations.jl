module Relations

using Compat
using Reexport
@reexport using NullableArrays
@reexport using StructuredQueries
const SQ = StructuredQueries
@reexport using CSV


export  Attributed,
        Relation

include("attributed.jl")
include("relation.jl")
include("utils.jl")
include("show.jl")

include("collect/attributive/select.jl")
include("collect/attributive/filter.jl")
include("collect/attributive/groupby.jl")
include("collect/attributive/summarize.jl")

include("collect/attributive/grouped/summarize.jl")

end # module
