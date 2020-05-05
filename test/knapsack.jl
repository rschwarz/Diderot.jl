using Diderot: Instance, State, Node, Arc

@testset "model methods" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.DecisionDiagram()

    @test Diderot.initial_state(inst) == State(4)

    @test Diderot.next_variable(inst, dd, Diderot.InOrder()) == 1
    @test Diderot.next_variable(inst, dd, Diderot.ByWeightDecr()) == 1

    @test Diderot.transitions(inst, State(2), 1) ==
        Dict(Arc(State(2), false, 0.0) => State(2))
    @test Diderot.transitions(inst, State(2), 2) ==
        Dict(Arc(State(2), false, 0.0) => State(2),
             Arc(State(2), true,  3.0) => State(0))

    inst2 = Instance([4.0, 3.0, 2.0], [2, 3, 2], 4)
    @test Diderot.next_variable(inst2, dd, Diderot.ByWeightDecr()) == 2
end

@testset "top-down decision diagrams" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.top_down(inst, Diderot.InOrder())

    # layers and nodes
    @test length(dd.layers) == 4

    @test length(dd.layers[1]) == 1 # root
    @test dd.layers[1][State(4)] == Node(nothing, 0.0)

    @test length(dd.layers[2]) == 2 # 4, 1
    @test dd.layers[2][State(4)] == Node(Arc(State(4), false, 0.0), 0.0)
    @test dd.layers[2][State(1)] == Node(Arc(State(4), true, 4.0), 4.0)

    @test length(dd.layers[3]) == 3 # 4, 2, 1
    @test dd.layers[3][State(4)] == Node(Arc(State(4), false, 0.0), 0.0)
    @test dd.layers[3][State(2)] == Node(Arc(State(4), true, 3.0), 3.0)
    @test dd.layers[3][State(1)] == Node(Arc(State(1), false, 0.0), 4.0)

    @test length(dd.layers[4]) == 1 # terminal
    @test dd.layers[4][State(0)] == Node(Arc(State(2), true, 2.0), 5.0)
end

@testset "longest path" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.top_down(inst, Diderot.InOrder())
    sol = Diderot.longest_path(dd)
    @test sol.decisions == [false, true, true]
    @test sol.objective ≈ 5.0

    inst2 = Instance([3.0, 4.0, 2.0], [2, 3, 2], 4)
    dd2 = Diderot.top_down(inst2, Diderot.ByWeightDecr())
    sol2 = Diderot.longest_path(dd2)
    @test sol2.decisions == [true, false, true]
    @test sol2.objective ≈ 5.0
end

@testset "restriction" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @testset "width 1" begin
        dd = Diderot.top_down(inst, Diderot.InOrder(),
                              process_layer=Diderot.RestrictLowDist(1))
        @test length(dd.layers) == 4
        @test all(l -> length(l) == 1, dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, false, false]
        @test sol.objective ≈ 4.0
    end

    @testset "width 2" begin
        dd = Diderot.top_down(inst, Diderot.InOrder(),
                              process_layer=Diderot.RestrictLowDist(2))
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
        dd = Diderot.top_down(inst, Diderot.InOrder(),
                              process_layer=Diderot.RelaxLowCap(1))
        @test length(dd.layers) == 4
        @test all(l -> length(l) == 1, dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, true, true]
        @test sol.objective ≈ 9.0
    end

    @testset "width 2" begin
        dd = Diderot.top_down(inst, Diderot.InOrder(),
                              process_layer=Diderot.RelaxLowCap(2))
        @test length(dd.layers) == 4
        @test all(l -> length(l) in (1, 2), dd.layers)

        sol = Diderot.longest_path(dd)
        @test sol.decisions == [true, false, true]
        @test sol.objective ≈ 6.0
    end
end
