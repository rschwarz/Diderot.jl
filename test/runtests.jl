using Test
using Diderot

@testset "internals" begin
    include("internals.jl")
end

@testset "Knapsack" begin
    include("knapsack.jl")
end

@testset "Set Cover" begin
    include("setcover.jl")
end
