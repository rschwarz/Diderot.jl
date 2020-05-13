using SparseArrays
using Diderot: Arc, Node
using Diderot.SetCover

const SC = SetCover

@testset "model" begin
    values = [-2.0, -3.0, -4.0, -2.0]
    sets = sparse(Bool[1 1 0 0; 0 1 1 0; 0 0 1 1])
    instance = SC.Instance(values, sets)

    @test Diderot.domain_type(instance) == Bool
    @test Diderot.value_type(instance) == Float64
    @test Diderot.initial_state(instance) == BitSet(1:3)
    @test length(instance) == 4

    @test Diderot.transitions(instance, BitSet(1:3), 1) ==
        Dict(Arc(BitSet(1:3), true, -2.0) => BitSet(2:3),
             Arc(BitSet(1:3), false, 0.0) => BitSet(1:3))
    @test Diderot.transitions(instance, BitSet(1:3), 2) ==
        Dict(Arc(BitSet(1:3), true, -3.0) => BitSet([3]))
    @test Diderot.transitions(instance, BitSet(1:3), 3) ==
        Dict(Arc(BitSet(1:3), true, -4.0) => BitSet([1]))
    @test Diderot.transitions(instance, BitSet(1:3), 4) ==
        Dict(Arc(BitSet(1:3), true, -2.0) => BitSet(1:2))
end

@testset "exact decision diagram" begin
    N = Node{BitSet,Bool,Float64}

    values = [-2.0, -3.0, -4.0, -2.0]
    sets = sparse(Bool[1 1 0 0; 0 1 1 0; 0 0 1 1])
    instance = SC.Instance(values, sets)

    # build diagram
    diagram = Diderot.Diagram(instance)
    Diderot.top_down!(diagram, instance)

    @test length(diagram.layers) == 5

    @test length(diagram.layers[1]) == 1
    @test diagram.layers[1][BitSet(1:3)] == N(0.0, nothing)

    @test length(diagram.layers[2]) == 2
    @test diagram.layers[2][BitSet(1:3)] ==
        N(0.0, Arc(BitSet(1:3), false, 0.0))
    @test diagram.layers[2][BitSet(2:3)] ==
        N(-2.0, Arc(BitSet(1:3), true, -2.0))

    # and so on ...

    @test length(diagram.layers[5]) == 1  # terminal

    # extract solution
    @test Diderot.longest_path(diagram) == Diderot.Solution([0, 1, 0, 1], -5.0)
end

@testset "restriction" begin
    values = [-2.0, -3.0, -4.0, -2.0]
    sets = sparse(Bool[1 1 0 0; 0 1 1 0; 0 0 1 1])
    instance = SC.Instance(values, sets)

    @testset "width 1" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(1))
        @test length(diagram.layers) == 5
        @test all(l -> length(l) == 1, diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [0, 1, 0, 1]
        @test solution.objective ≈ -5.0 # optimal!
    end

    @testset "width 2" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(2))
        @test length(diagram.layers) == 5
        @test all(l -> length(l) <= 2, diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [0, 1, 0, 1]
        @test solution.objective ≈ -5.0 # optimal!
    end
end
