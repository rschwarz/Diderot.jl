using Diderot: Arc, Node
using Diderot.Knapsack: Instance, ByWeightDecr, RestrictLowDist, RelaxLowCap

const N = Node{Int,Bool,Float64}

@testset "model methods" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @test Diderot.initial_state(inst) == 4
    @test Diderot.value_type(inst) == Float64
    @test Diderot.domain_type(inst) == Bool

    dd = Diderot.DecisionDiagram(inst)

    @test Diderot.next_variable(inst, dd, Diderot.VarsInOrder()) == 1
    @test Diderot.next_variable(inst, dd, ByWeightDecr()) == 1

    @test Diderot.transitions(inst, 2, 1) ==
        Dict(Arc(2, false, 0.0) => 2)
    @test Diderot.transitions(inst, 2, 2) ==
        Dict(Arc(2, false, 0.0) => 2,
             Arc(2, true,  3.0) => 0)

    inst2 = Instance([4.0, 3.0, 2.0], [2, 3, 2], 4)
    @test Diderot.next_variable(inst2, dd, ByWeightDecr()) == 2
end

@testset "top-down decision diagrams" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.DecisionDiagram(inst)
    Diderot.top_down!(dd, inst)

    # layers and nodes
    @test length(dd.layers) == 4

    @test length(dd.layers[1]) == 1 # root
    @test dd.layers[1][4] == N(0.0, nothing)

    @test length(dd.layers[2]) == 2 # 4, 1
    @test dd.layers[2][4] == N(0.0, Arc(4, false, 0.0))
    @test dd.layers[2][1] == N(4.0, Arc(4, true, 4.0))

    @test length(dd.layers[3]) == 3 # 4, 2, 1
    @test dd.layers[3][4] == N(0.0, Arc(4, false, 0.0))
    @test dd.layers[3][2] == N(3.0, Arc(4, true, 3.0))
    @test dd.layers[3][1] == N(4.0, Arc(1, false, 0.0))

    @test length(dd.layers[4]) == 1 # terminal
    @test dd.layers[4][0] == N(5.0, Arc(2, true, 2.0))
end

@testset "longest path" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.DecisionDiagram(inst)
    Diderot.top_down!(dd, inst)
    sol = Diderot.longest_path(dd)
    @test sol.decisions == [false, true, true]
    @test sol.objective ≈ 5.0

    inst2 = Instance([3.0, 4.0, 2.0], [2, 3, 2], 4)
    dd2 = Diderot.DecisionDiagram(inst2)
    Diderot.top_down!(dd2, inst2, var_order=ByWeightDecr())
    sol2 = Diderot.longest_path(dd2)
    @test sol2.decisions == [true, false, true]
    @test sol2.objective ≈ 5.0
end

@testset "restriction" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @testset "width 1" begin
        dd = Diderot.DecisionDiagram(inst)
        Diderot.top_down!(dd, inst, process_layer=RestrictLowDist(1))
        @test length(dd.layers) == 4
        @test all(l -> length(l) == 1, dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, false, false]
        @test sol.objective ≈ 4.0
    end

    @testset "width 2" begin
        dd = Diderot.DecisionDiagram(inst)
        Diderot.top_down!(dd, inst, process_layer=RestrictLowDist(2))
        @test length(dd.layers) == 4
        @test all(l -> length(l) in (1, 2), dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [false, true, true]
        @test sol.objective ≈ 5.0 # optimum!
    end
end

@testset "relaxation" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @testset "width 1" begin
        dd = Diderot.DecisionDiagram(inst)
        Diderot.top_down!(dd, inst, process_layer=RelaxLowCap(1))
        @test length(dd.layers) == 4
        @test all(l -> length(l) == 1, dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, true, true]
        @test sol.objective ≈ 9.0
    end

    @testset "width 2" begin
        dd = Diderot.DecisionDiagram(inst)
        Diderot.top_down!(dd, inst, process_layer=RelaxLowCap(2))
        @test length(dd.layers) == 4
        @test all(l -> length(l) in (1, 2), dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, false, true]
        @test sol.objective ≈ 6.0
    end
end

@testset "branch and bound" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    # Relaxation needs at least width 2 for branching.

    @testset "width 1" begin
        sol = Diderot.branch_and_bound(inst, restrict=RestrictLowDist(1),
                                       relax=RelaxLowCap(2))
        @test sol.decisions == [false, true, true]
        @test sol.objective ≈ 5.0
    end

    @testset "width 2" begin
        sol = Diderot.branch_and_bound(inst, restrict=RestrictLowDist(2),
                                       relax=RelaxLowCap(2))
        @test sol.decisions == [false, true, true]
        @test sol.objective ≈ 5.0
    end

    @testset "width 3" begin
        sol = Diderot.branch_and_bound(inst, restrict=RestrictLowDist(3),
                                       relax=RelaxLowCap(3))
        @test sol.decisions == [false, true, true]
        @test sol.objective ≈ 5.0
    end

    @testset "n 5, width 2" begin
        inst2 = Instance([5, 3, 2, 7, 4], [2, 8, 4, 2, 5], 10)
        sol = Diderot.branch_and_bound(inst2, restrict=RestrictLowDist(2),
                                       relax=RelaxLowCap(2))
        @test sol.decisions == [1, 0, 0, 1, 1]
        @test sol.objective ≈ 16.0
    end
end
