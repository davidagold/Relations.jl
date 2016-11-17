# Relations
*A circumspect interface for relational data*

[![Build Status](https://travis-ci.org/davidagold/Relations.jl.svg?branch=master)](https://travis-ci.org/davidagold/Relations.jl)
[![Coverage Status](https://coveralls.io/repos/davidagold/Relations.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/davidagold/Relations.jl?branch=master)
[![codecov.io](http://codecov.io/github/davidagold/Relations.jl/coverage.svg?branch=master)](http://codecov.io/github/davidagold/Relations.jl?branch=master)

## Installation

This package is not yet registered. Install it with

```julia
Pkg.clone("https://github.com/davidagold/Relations.jl.git")
```

## What is this library?

This library lets you wrap certain objects as `Relation`s. You can treat a `Relation` like a bag of tuples. Right now the primary functionality that this supports is data manipulation via `@with`.


## Why did you make this?

I wrote [StructuredQueries](https://github.com/davidagold/StructuredQueries.jl/) as a framework for representing manipulations over diverse data sources. Given such a representation, one can then define a semantics for collecting or executing the given manipulations against particular data sources. But I didn't know where to put the code that implemented these semantics.

[AbstractTables](https://github.com/davidagold/AbstractTables.jl) was a first attempt to come up with such a home. The code it housed was intended to be generic over a certain class of "column-indexable" species. But the generality was based on inheritance (from the `AbstractTable` abstract type) and I don't think this is the most appropriate model. There are a number of different data types that can represent a bag of tuples. These may belong to type hierarchies that reflect other aspects of their functionality/behavior as well. To expect all such data types that we'd like to treat as bags of tuples to fall under this one node in the type lattice is unreasonable.

Really, what we want is an interface that lets us treat certain data types as bags of tuples regardless of where they belong in the type lattice, as long as they satisfy certain behaviors or others. The `Relation` type this library provides is intended as a wrapper that (in theory) lets us do precisely that.

Some types may satisfy behavior requirements only for certain protocols with which we treat `Relation`s as bags of tuples. For instance, a `Relation` that wraps a `CSV.Source` may only be iterable as a container of tuples, whereas a `Relation` that wraps a tuple of `NullableVector`s may be linearly indexable. (NOTE: So far, only wrapping "columns" of `AbstractVector`s is currently supported. I hope to remedy this limitation in December.) The semantics this library offers are intended to be *mostly* consistent over sources that support different protocols, and we try to make all exceptions very explicit. For the most part, differences between protocol support should affect only things like performance.

I drew a significant amount of inspiration from Jeff Bezanson's and others' work in [IndexedTables.jl](https://github.com/JuliaComputing/IndexedTables.jl), from [NamedTuples.jl](https://github.com/blackrock/NamedTuples.jl/), and from the ideas in David Anthoff's [Query.jl](https://github.com/davidanthoff/Query.jl/).

## What does using this library look like?

Right now, the only supported sources for `Relation`s are in-memory Julia vectors. (Again, I hope to expand this in due time.) You can create a `Relation` much the same way you can create a `DataFrame`:

```julia
julia> r = Relation(A=rand(5), B=rand(1:3,5))
Relation (in-memory Julia source)
│ #     A          B  
├─────┼──────────┼───┤
│ 1     0.185199   1  
│ 2     0.508584   1  
│ 3     0.912091   3  
│ 4     0.484842   1  
│ 5     0.540283   1  
```

The interface for manipulating a `Relation` is deliberately limited. For instance, you can't index into a `Relation` by attribute, except by messing with its internals

```julia
julia> r[:A]
ERROR: indexing Array{Float64,1} with types Tuple{Symbol} is not supported
 in ith_all at /Users/David/.julia/v0.6/Relations/src/utils.jl:4 [inlined]
 in getindex(::Relations.Relation{Relations.##297{Array{Float64,1},Array{Int64,1}},Relations.##297{Float64,Int64}}, ::Symbol) at /Users/David/.julia/v0.6/Relations/src/relation.jl:63

julia> r.src.A
5-element Array{Float64,1}:
 0.185199
 0.508584
 0.912091
 0.484842
 0.540283
```

There are two things to note above. The first is that we've accessed the `A` column through the `:A` field of `r.src`, which is in fact a named-tuple-esque object referred to herein as an `Attributed`:

```julia
julia> typeof(r.src)
Relations.##297{Array{Float64,1},Array{Int64,1}}

julia> supertype(ans)
Relations.Attributed
```

So, columns of Julia vectors are stored in a `Relation` via a parametric `Attributed` leaf-type. This same leaf-type (but with different parameters) is also the `eltype` of the `Relation`:

```julia
julia> eltype(r)
Relations.##297{Float64,Int64}
```

Indeed, iterating over a `Relation` produces `Attributed` objects:

```julia
julia> i = first(r)
(0.1851989900175528,1)

julia> i.A, i.B
(0.1851989900175528,1)
```

The second thing to note is that binding "columns" together in a `Relation` does not promote them to `DataArray`s or `NullableArray`s. If you put regular `Array`s into a `Relation`, they will stay that way (but resultant columns produced via manipulations that involve `Nullable` objects will produce `NullableArray` columns).

## Manipulation

See the examples in the [Collect.jl](https://github.com/davidagold/Collect.jl) [README](https://github.com/davidagold/Collect.jl/blob/master/README.md) for examples of how to use the StructuredQueries manipulation interface with `Relation` objects. Any such manipulation that can be performed on a `DataFrame` can be performed on a `Relation`. Indeed, manipulation graphs are executed against `DataFrame` objects by wrapping them in `Relation`s and acting on the latter.
