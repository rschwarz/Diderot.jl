module Diderot

using DataStructures

## Core

include("types.jl")
include("interface.jl")
include("implementation.jl")

## Generic implementation

include("restriction.jl")

## Specific implementation for problem classes.

include("knapsack.jl")
include("setcover.jl")

end
