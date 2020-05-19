module Diderot

using DataStructures

## Core

include("types.jl")
include("interface.jl")
include("implementation.jl")

## Generic implementation

include("restriction.jl")
include("relaxation.jl")

## Specific implementation for problem classes.

include("knapsack.jl")
include("setcover.jl")


# add README as docstring to module
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end Diderot

end
