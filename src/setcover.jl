module SetCover

using SparseArrays
using ..Diderot
using ..Diderot: Arc, Node, Layer

struct Instance
    values::Vector{Float64}         # minimize total
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
Diderot.initial_state(instance::Instance) = BitSet(1:length(instance))

function Diderot.transitions(instance::Instance, state, variable)
    results = Dict{Arc{BitSet, Bool, Float64}, BitSet}()

    # Sets that are covered by this element.
    covered = BitSet(findall(instance.sets[:, variable]))

    # true: select element, remove all sets that are covered.
    cost = -1.0 * instance.value(variable)   # negated since it's maximized
    results[state, true, cost] = setdiff(state, covered)

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

end
