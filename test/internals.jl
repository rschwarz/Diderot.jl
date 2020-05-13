using Diderot: Arc, Node

@testset "struct equality" begin
    @test Arc(1, true, 1.0) == Arc(1, true, 1.0)
    @test Arc(1, true, 1.0) != Arc(0, true, 1.0)
    @test Arc(1, true, 1.0) != Arc(1, false, 1.0)
    @test Arc(1, true, 1.0) != Arc(1, true, 1.1)

    @test Arc(BitSet(1:3), 1, 0.0) == Arc(BitSet(1:3), 1, 0.0)

    N = Node{Int,Int,Int}
    @test N(1, Arc(1, 1, 1), true) == N(1, Arc(1, 1, 1), true)
    @test N(1, Arc(1, 1, 1), true) != N(1, nothing, true)
    @test N(1, Arc(1, 1, 1), true) != N(1, Arc(1, 1, 1), false)
    @test N(1, nothing, true) == N(1, nothing, true)
end
