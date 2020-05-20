using Diderot: Arc, Node, RestrictLowDistance
using Diderot.IndexFund

const IF = IndexFund

function make_instance(number)
    weights = [0.4, 0.2, 0.2, 0.1, 0.1]
    similarity = [
        1.0    0.1   -0.1    0.08   0.51
        0.1    1.0    0.07  -0.61   0.55
       -0.1    0.07   1.0    0.27   0.46
        0.08  -0.61   0.27   1.0   -0.3
        0.51   0.55   0.46  -0.3    1.0
    ]
    return IF.Instance(weights, similarity, number)
end

@testset "model" begin
    instance = make_instance(2)

    @test Diderot.domain_type(instance) == Int
    @test Diderot.value_type(instance) == Float64
    @test Diderot.initial_state(instance)== BitSet()
    @test length(instance) == 5

    @test Diderot.transitions(instance, BitSet(), 1) ==
        Dict(Arc(BitSet(), 1, 0.4 * 1.0)    => BitSet(1),
             Arc(BitSet(), 2, 0.4 * 0.1)    => BitSet(2),
             Arc(BitSet(), 3, 0.4 * (-0.1)) => BitSet(3),
             Arc(BitSet(), 4, 0.4 * 0.08)   => BitSet(4),
             Arc(BitSet(), 5, 0.4 * 0.51)   => BitSet(5))
    @test Diderot.transitions(instance, BitSet(1), 1) ==
        Dict(Arc(BitSet(1), 1, 0.4 * 1.0)    => BitSet(1),
             Arc(BitSet(1), 2, 0.4 * 0.1)    => BitSet(1:2),
             Arc(BitSet(1), 3, 0.4 * (-0.1)) => BitSet([1,3]),
             Arc(BitSet(1), 4, 0.4 * 0.08)   => BitSet([1,4]),
             Arc(BitSet(1), 5, 0.4 * 0.51)   => BitSet([1,5]))
    @test Diderot.transitions(instance, BitSet(1:2), 1) ==
        Dict(Arc(BitSet(1:2), 1, 0.4 * 1.0)    => BitSet(1:2))
end

@testset "exact diagram" begin
    N = Node{BitSet,Int,Float64}

    instance = make_instance(2)
    diagram = Diderot.Diagram(instance)
    Diderot.top_down!(diagram, instance)

    @test length(diagram.layers) == 6

    @test length(diagram.layers[1]) == 1
    @test diagram.layers[1][BitSet()] == N(0.0, nothing)

    @test length(diagram.layers[2]) == 5
    @test diagram.layers[2][BitSet(1)] ≈ N(0.4, Arc(BitSet(), 1, 0.4))
    @test diagram.layers[2][BitSet(2)] ≈ N(0.04, Arc(BitSet(), 2, 0.04))
    # ...

    @test length(diagram.layers[end]) == 1

    solution = Diderot.longest_path(diagram)
    @test solution.decisions == [1, 5, 5, 1, 5]
    @test solution.objective ≈ 0.71
end

@testset "restriction" begin
    instance = make_instance(2)

    @testset "width 1" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(1))
        @test length(diagram.layers) == 6
        @test all(l -> length(l) == 1, diagram.layers)
        solution = Diderot.longest_path(diagram)
        @test solution.objective <= 0.72
    end

    @testset "width 2" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(2))
        @test length(diagram.layers) == 6
        @test all(l -> length(l) <= 2, diagram.layers)
        solution = Diderot.longest_path(diagram)
        @test solution.objective <= 0.72
    end
end

@testset "relaxation" begin
    instance = make_instance(2)

    @testset "width 1" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=IF.relax(1))
        @test length(diagram.layers) == 6
        @test all(l -> length(l) == 1, diagram.layers)
        solution = Diderot.longest_path(diagram)
        @test solution.objective >= 0.7
    end

    @testset "width 2" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=IF.relax(2))
        @test length(diagram.layers) == 6
        @test all(l -> length(l) <= 2, diagram.layers)
        solution = Diderot.longest_path(diagram)
        @test solution.objective >= 0.7
    end
end

@testset "branch and bound" begin
    instance = make_instance(2)

    # need at least width 5 for exact cutsets to branch on
    @testset "width 5" begin
        solution = Diderot.branch_and_bound(
            instance, restrict=RestrictLowDistance(5), relax=IF.relax(5))
        @test solution.decisions == [1, 5, 5, 1, 5]
        @test solution.objective ≈ 0.71
    end

    @testset "width 10" begin
        solution = Diderot.branch_and_bound(
            instance, restrict=RestrictLowDistance(10), relax=IF.relax(10))
        @test solution.decisions == [1, 5, 5, 1, 5]
        @test solution.objective ≈ 0.71
    end
end
