module Diderot

using DataStructures

include("types.jl")
include("interface.jl")
include("implementation.jl")

## Specific Implementation for problem classes.

include("knapsack.jl")
include("setcover.jl")

end
