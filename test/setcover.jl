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
