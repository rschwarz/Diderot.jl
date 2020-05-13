module SetCover

using SparseArrays
using ..Diderot
using ..Diderot: Arc, Node, Layer

struct Instance
    values::Vector{Float64}         # should be negative (is maximized)
    sets::SparseMatrixCSC{Bool,Int} # rows == sets to cover

    function Instance(values, sets)
        @assert length(values) == size(sets, 2)
        @assert all(sum.(eachrow(sets)) .> 0) # feasible
        return new(values, sets)
    end
end

Base.length(instance::Instance) = length(instance.values)
Diderot.domain_type(instance::Instance) = Bool
Diderot.value_type(instance::Instance) = Float64
Diderot.initial_state(instance::Instance) = BitSet(1:size(instance.sets, 1))

function Diderot.transitions(instance::Instance, state, variable)
    results = Dict{Arc{BitSet, Bool, Float64}, BitSet}()

    # Sets that are covered by this element.
    covered = BitSet(findall(instance.sets[:, variable]))

    # true: select element, remove all sets that are covered.
    results[Arc(state, true, instance.values[variable])] =
        setdiff(state, covered)

    # false: don't select element, state is unchanged.
    #
    # Need to check if this could be infeasible. For now, assume that variable
    # order is static, then we can check whether this variable was the "last
    # chance" for any set to cover.
    for set in intersect(covered, state)
        if variable == last(findall(instance.sets[set, :]))
            # Must add this element, so we don't add "false" transition.
            return results
        end
    end

    # Don't need this element, so we add "false" transition.
    results[Arc(state, false, 0.0)] = state

    return results
end

struct RelaxLargest
    max_width::Int
end

function Diderot.process(
    relax::RelaxLargest, layer::Layer{S,D,V}
) where {S,D,V}
    if length(layer) <= relax.max_width
        return layer
    end

    # sort states by number of sets to cover still
    candidates = collect(layer)
    sort!(candidates, by=tup -> length(tup.first))

    # keep first (width - 1) unchanged
    new_layer = Layer{S,D,V}(Dict(candidates[1:(relax.max_width - 1)]), false)

    # merge the rest:
    # - take intersection of sets to cover
    # - use predecessor for longest distance
    rest = @view candidates[relax.max_width:end]
    merged_state = foldl(intersect, first.(rest))
    index = argmax(map(pair -> pair.second.distance, rest))
    merged_node = rest[index].second
    new_node = Node{S,D,V}(merged_node.distance, merged_node.inarc, false)
    new_layer[merged_state] = new_node

    return new_layer
end

end
