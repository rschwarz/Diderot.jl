using Diderot: Arc, Node
using Diderot.Knapsack: Instance, DecreasingWeight, RestrictLowDistance,
                        RelaxLowCapacity

@testset "model methods" begin
    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @test Diderot.initial_state(instance) == 4
    @test Diderot.value_type(instance) == Float64
    @test Diderot.domain_type(instance) == Bool

    diagram = Diderot.Diagram(instance)

    @test Diderot.next_variable(instance, diagram, Diderot.InOrder()) == 1
    @test Diderot.next_variable(instance, diagram, DecreasingWeight()) == 1

    @test Diderot.transitions(instance, 2, 1) ==
        Dict(Arc(2, false, 0.0) => 2)
    @test Diderot.transitions(instance, 2, 2) ==
        Dict(Arc(2, false, 0.0) => 2,
             Arc(2, true,  3.0) => 0)

    instance2 = Instance([4.0, 3.0, 2.0], [2, 3, 2], 4)
    @test Diderot.next_variable(instance2, diagram, DecreasingWeight()) == 2
end

@testset "top-down decision diagrams" begin
    N = Node{Int,Bool,Float64}

    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    diagram = Diderot.Diagram(instance)
    Diderot.top_down!(diagram, instance)

    # layers and nodes
    @test length(diagram.layers) == 4

    @test length(diagram.layers[1]) == 1 # root
    @test diagram.layers[1][4] == N(0.0, nothing)

    @test length(diagram.layers[2]) == 2 # 4, 1
    @test diagram.layers[2][4] == N(0.0, Arc(4, false, 0.0))
    @test diagram.layers[2][1] == N(4.0, Arc(4, true, 4.0))

    @test length(diagram.layers[3]) == 3 # 4, 2, 1
    @test diagram.layers[3][4] == N(0.0, Arc(4, false, 0.0))
    @test diagram.layers[3][2] == N(3.0, Arc(4, true, 3.0))
    @test diagram.layers[3][1] == N(4.0, Arc(1, false, 0.0))

    @test length(diagram.layers[4]) == 1 # terminal
    @test diagram.layers[4][0] == N(5.0, Arc(2, true, 2.0))
end

@testset "longest path" begin
    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    diagram = Diderot.Diagram(instance)
    Diderot.top_down!(diagram, instance)
    solution = Diderot.longest_path(diagram)
    @test solution.decisions == [false, true, true]
    @test solution.objective ≈ 5.0

    instance2 = Instance([3.0, 4.0, 2.0], [2, 3, 2], 4)
    diagram2 = Diderot.Diagram(instance2)
    Diderot.top_down!(diagram2, instance2, variable_order=DecreasingWeight())
    solution2 = Diderot.longest_path(diagram2)
    @test solution2.decisions == [true, false, true]
    @test solution2.objective ≈ 5.0
end

@testset "restriction" begin
    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @testset "width 1" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(1))
        @test length(diagram.layers) == 4
        @test all(l -> length(l) == 1, diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [true, false, false]
        @test solution.objective ≈ 4.0
    end

    @testset "width 2" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RestrictLowDistance(2))
        @test length(diagram.layers) == 4
        @test all(l -> length(l) in (1, 2), diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [false, true, true]
        @test solution.objective ≈ 5.0 # optimum!
    end
end

@testset "relaxation" begin
    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @testset "width 1" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RelaxLowCapacity(1))
        @test length(diagram.layers) == 4
        @test all(l -> length(l) == 1, diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [true, true, true]
        @test solution.objective ≈ 9.0
    end

    @testset "width 2" begin
        diagram = Diderot.Diagram(instance)
        Diderot.top_down!(diagram, instance, processing=RelaxLowCapacity(2))
        @test length(diagram.layers) == 4
        @test all(l -> length(l) in (1, 2), diagram.layers)

        solution = Diderot.longest_path(diagram)
        @test solution.decisions == [true, false, true]
        @test solution.objective ≈ 6.0
    end
end

@testset "branch and bound" begin
    instance = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    # Relaxation needs at least width 2 for branching.

    @testset "width 1" begin
        solution = Diderot.branch_and_bound(
            instance, restrict=RestrictLowDistance(1), relax=RelaxLowCapacity(2))
        @test solution.decisions == [false, true, true]
        @test solution.objective ≈ 5.0
    end

    @testset "width 2" begin
        solution = Diderot.branch_and_bound(
            instance, restrict=RestrictLowDistance(2), relax=RelaxLowCapacity(2))
        @test solution.decisions == [false, true, true]
        @test solution.objective ≈ 5.0
    end

    @testset "width 3" begin
        solution = Diderot.branch_and_bound(
            instance, restrict=RestrictLowDistance(3), relax=RelaxLowCapacity(3))
        @test solution.decisions == [false, true, true]
        @test solution.objective ≈ 5.0
    end

    @testset "n 5, width 2" begin
        instance2 = Instance([5, 3, 2, 7, 4], [2, 8, 4, 2, 5], 10)
        solution = Diderot.branch_and_bound(
            instance2, restrict=RestrictLowDistance(2), relax=RelaxLowCapacity(2))
        @test solution.decisions == [1, 0, 0, 1, 1]
        @test solution.objective ≈ 16.0
    end
end
