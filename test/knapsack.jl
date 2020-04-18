using Diderot: Instance, State, Transition, Node, Arc

@testset "model methods" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @test Diderot.initial_state(inst) == State(4)
    @test collect(Diderot.VarsInOrder(inst)) == [1, 2, 3]
    @test collect(Diderot.VarsByWeightDecr(inst)) == [1, 2, 3]

    @test Diderot.transition(inst, State(2), 1, false) ==
        Transition(State(2), 0.0)
    @test Diderot.transition(inst, State(2), 1, true) == Diderot.Infeasible()
    @test Diderot.transition(inst, State(2), 2, true) ==
        Transition(State(0), 3.0)

    inst2 = Instance([4.0, 3.0, 2.0], [2, 3, 2], 4)
    @test collect(Diderot.VarsByWeightDecr(inst2)) == [2, 1, 3]
end

@testset "top-down decision diagrams" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.top_down(inst, Diderot.VarsInOrder(inst))

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
    dd = Diderot.top_down(inst, Diderot.VarsInOrder(inst))
    sol = Diderot.longest_path(dd)
    @test sol.decisions == [false, true, true]
    @test sol.objective ≈ 5.0

    inst2 = Instance([3.0, 4.0, 2.0], [2, 3, 2], 4)
    dd2 = Diderot.top_down(inst2, Diderot.VarsByWeightDecr(inst))
    sol2 = Diderot.longest_path(dd2)
    @test sol2.decisions == [true, false, true]
    @test sol2.objective ≈ 5.0
end
