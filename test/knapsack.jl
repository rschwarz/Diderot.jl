using Diderot: Instance, State, Transition, Node, Arc

@testset "model methods" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)

    @test Diderot.variables(inst) == 1:3
    @test Diderot.initial_state(inst) == State(4)
    @test Diderot.terminal_state(inst) == State(-1)

    @test Diderot.transition(inst, State(2), 1, false) ==
        Transition(State(2), 0.0)
    @test Diderot.transition(inst, State(2), 1, true) == Diderot.Infeasible()
    @test Diderot.transition(inst, State(2), 2, true) ==
        Transition(State(0), 3.0)
end

@testset "top-down decision diagrams" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.top_down(inst)

    # layers and nodes
    @test length(dd.layers) == 4
    @test length(dd.layers[1]) == 1 # root
    @test Node(1, State(4)) in dd.layers[1]
    @test length(dd.layers[2]) == 2 # 4, 1
    @test Node(2, State(4)) in dd.layers[2]
    @test Node(2, State(1)) in dd.layers[2]
    @test length(dd.layers[3]) == 3 # 4, 2, 1
    @test Node(3, State(4)) in dd.layers[3]
    @test Node(3, State(2)) in dd.layers[3]
    @test Node(3, State(1)) in dd.layers[3]
    @test length(dd.layers[4]) == 1 # terminal
    @test Node(4, State(-1)) in dd.layers[4]

    # arcs
    @test length(dd.inarcs) == 6
    @test dd.inarcs[Node(2, State(4))] == [Arc(Node(1, State(4)), false, 0.0)]
    @test dd.inarcs[Node(2, State(1))] == [Arc(Node(1, State(4)), true,  4.0)]
    @test dd.inarcs[Node(3, State(4))] == [Arc(Node(2, State(4)), false, 0.0)]
    @test dd.inarcs[Node(3, State(2))] == [Arc(Node(2, State(4)), true,  3.0)]
    @test dd.inarcs[Node(3, State(1))] == [Arc(Node(2, State(1)), false, 0.0)]
    @test Set(dd.inarcs[Node(4, State(-1))]) == Set([
        Arc(Node(3, State(4)), false, 0.0),
        Arc(Node(3, State(4)), true,  2.0),
        Arc(Node(3, State(2)), false, 0.0),
        Arc(Node(3, State(2)), true,  2.0),
        Arc(Node(3, State(1)), false, 0.0),
    ])
end

@testset "longest path" begin
    inst = Instance([4.0, 3.0, 2.0], [3, 2, 2], 4)
    dd = Diderot.top_down(inst)
    sol = Diderot.longest_path(dd)
    @test sol.decisions == [false, true, true]
    @test sol.objective ≈ 5.0
end
