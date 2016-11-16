# Relations
*A circumspect interface for relational data*

[![Build Status](https://travis-ci.org/davidagold/Relations.jl.svg?branch=master)](https://travis-ci.org/davidagold/Relations.jl)

[![Coverage Status](https://coveralls.io/repos/davidagold/Relations.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/davidagold/Relations.jl?branch=master)

[![codecov.io](http://codecov.io/github/davidagold/Relations.jl/coverage.svg?branch=master)](http://codecov.io/github/davidagold/Relations.jl?branch=master)

## What is this library?

This library lets you wrap certain objects as `Relation`s. You can treat a `Relation` like a bag of tuples. Right now the primary functionality that this supports is data manipulation via `@with`. The latter can be used against other sources, such as a `DataFrame`, to produce `Relation`s -- see the "What does using this library look like?" section below.


## Why did you make this?

I wrote


[AbstractTables] was a first attempt to describe generic functionality over relational data sources. It was based on inheritance. But this isn't an appropriate model. There are a number of different data types that can represent a bag of tuples. These may belong to type hierarchies that reflect other aspects of their functionality/behavior as well. So to expect ...

Really, what we want is an interface that lets us treat certain data types as bags of tuples regardless of where they belong in the type lattice, as long as they satisfy certain behaviors.

Some types may satisfy behavior requirements only for certain protocols with which we treat `Relation`s as bags of tuples. For instance, a `Relation` that wraps a `CSV.Source` may only be iterable as a container of tuples, whereas a `Relation` that wraps a tuple of `NullableVector`s may be linearly indexable.
The semantics this library offers are intended to be *mostly* consistent over sources that support different protocols, and we try to make all exceptions very explicit. For the most part, differences between protocol support should affect only things like performance.


## What does using this library look like?

Use `@with` to manipulate data:

```julia
julia> iris
150×5 DataFrames.DataFrame
│ Row │ sepal_length │ sepal_width │ petal_length │ petal_width │ species     │
├─────┼──────────────┼─────────────┼──────────────┼─────────────┼─────────────┤
│ 1   │ 5.1          │ 3.5         │ 1.4          │ 0.2         │ "setosa"    │
│ 2   │ 4.9          │ 3.0         │ 1.4          │ 0.2         │ "setosa"    │
│ 3   │ 4.7          │ 3.2         │ 1.3          │ 0.2         │ "setosa"    │
│ 4   │ 4.6          │ 3.1         │ 1.5          │ 0.2         │ "setosa"    │
│ 5   │ 5.0          │ 3.6         │ 1.4          │ 0.2         │ "setosa"    │
│ 6   │ 5.4          │ 3.9         │ 1.7          │ 0.4         │ "setosa"    │
# remaining output suppressed

julia> res = @with iris(i) filter(i.sepal_length > 7.0)
Relation (source of type Relations.##279{NullableArrays.NullableArray{Float64,1},NullableArrays.NullableArray{Float64,1},NullableArrays.NullableArray{Float64,1},NullableArrays.NullableArray{Float64,1},NullableArrays.NullableArray{WeakRefString{UInt8},1}})
⋮
│ #     sepal_length   sepal_width   petal_length   petal_width   species      
├─────┼──────────────┼─────────────┼──────────────┼─────────────┼─────────────┤
│ 1     7.1            3.0           5.9            2.1           "virginica"  
│ 2     7.6            3.0           6.6            2.1           "virginica"  
│ 3     7.3            2.9           6.3            1.8           "virginica"  
│ 4     7.2            3.6           6.1            2.5           "virginica"  
│ 5     7.7            3.8           6.7            2.2           "virginica"  
│ 6     7.7            2.6           6.9            2.3           "virginica"  
│ 7     7.7            2.8           6.7            2.0           "virginica"  
│ 8     7.2            3.2           6.0            1.8           "virginica"  
│ 9     7.2            3.0           5.8            1.6           "virginica"  
│ 10    7.4            2.8           6.1            1.9           "virginica"  
⋮
with 2 more rows.
```

In general, `@with` produces a `Cursor` object over the argument data source(s):

```julia
julia> X = NullableArray(rand(10));

julia> @with X(i) filter(i > .5)
Cursor over a Tuple{NullableArrays.NullableArray{Float64,1}}
```

But, as can be seen above, for certain sources such as `DataFrame`s, `@with` will automatically `collect` the resultant `Cursor` over the source(s).

It is very easy (and cheap) to turn a (column-based) `Relation` into a `DataFrame`.

```julia
julia> DataFrame(res)
12×5 DataFrames.DataFrame
│ Row │ sepal_length │ sepal_width │ petal_length │ petal_width │ species     │
├─────┼──────────────┼─────────────┼──────────────┼─────────────┼─────────────┤
│ 1   │ 7.1          │ 3.0         │ 5.9          │ 2.1         │ "virginica" │
│ 2   │ 7.6          │ 3.0         │ 6.6          │ 2.1         │ "virginica" │
│ 3   │ 7.3          │ 2.9         │ 6.3          │ 1.8         │ "virginica" │
│ 4   │ 7.2          │ 3.6         │ 6.1          │ 2.5         │ "virginica" │
│ 5   │ 7.7          │ 3.8         │ 6.7          │ 2.2         │ "virginica" │
│ 6   │ 7.7          │ 2.6         │ 6.9          │ 2.3         │ "virginica" │
│ 7   │ 7.7          │ 2.8         │ 6.7          │ 2.0         │ "virginica" │
│ 8   │ 7.2          │ 3.2         │ 6.0          │ 1.8         │ "virginica" │
│ 9   │ 7.2          │ 3.0         │ 5.8          │ 1.6         │ "virginica" │
│ 10  │ 7.4          │ 2.8         │ 6.1          │ 1.9         │ "virginica" │
│ 11  │ 7.9          │ 3.8         │ 6.4          │ 2.0         │ "virginica" │
│ 12  │ 7.7          │ 3.0         │ 6.1          │ 2.3         │ "virginica" │
```

## How do I use this with DataFrames.jl?

The `DataFrame` type stores relational data as Julia in-memory `AbstractVectors` ("vectors" for short) and varyingly supports directly addressing these internal components (the vectors) through the `DataFrame` interface. A `Relation` that wraps an (attributed) tuple of vectors employs a similar storage pattern for the data, but it does not support access to these vectors except through the built-in `getfield`. Rather, ...

The interface is more limited, but it may be more relevant to what you'd like to do -- especially if you're working with missing data.

Representing missing data is tricky. In Julia, ...

So, you can use `@with` to manipulate a `DataFrame` (though we clarify that "manipulation" does not mutate the data). In general, this will produce a `Relation`. You can manipulate this `Relation` in the same way, or you can convert it back to a `DataFrame` (or stream it to some other data sink).


## What should I know before using this library?

You probably shouldn't use this library -- yet. It's still under heavy development. I hope to tag version 0.1 by the end of the year.

If you're going to play with this package anyway, you should know the following. Recall how we said above that we guarantee consistent lifting semantics. For nearly all "scalar" functions (i.e., functions applied to one observation at a time), those semantics are...


## Where is this going?

```julia
@do iris filter(sepal_length)
```
