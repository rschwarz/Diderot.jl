module IndexFund

using ..Diderot
using ..Diderot: Arc, Node, Layer

struct Instance
    weights::Vector{Float64}
    similarity::Matrix{Float64}
    number::Int

    function Instance(weights, similarity, number)
        @assert length(weights) == size(similarity, 1)
        @assert size(similarity, 1) == size(similarity, 2)
        @assert number < length(weights)
        return new(weights, similarity, number)
    end
end

# Choose a representative for each stock.
Base.length(instance::Instance) = length(instance.weights)
Diderot.domain_type(instance::Instance) = Int

# Maximize weighted sum of similarities.
Diderot.value_type(instance::Instance) = Float64

# State encodes the stocks already picked (limited cardinality).
Diderot.initial_state(instance::Instance) = BitSet()

function Diderot.transitions(instance::Instance, state, variable)
    results = Dict{Arc{BitSet, Int, Float64}, BitSet}()

    N = length(instance)
    weight = instance.weight[variable]
    similarity = instance.similarity[:, variable]

    # Could we add another stock to the fund?
    if length(state) < instance.number
        for repr in setdiff(1:N, state)
            value = weight * similarity[repr]
            results[Arc(state, repr, value)] = union(state, repr)
        end
    end

    # Pick most similar stock already in the fund.
    if !isempty(state)
        best_repr, best_similarity = 0, -Inf
        for repr in state
            if similarity[repr] > best_similarity
                best_repr = repr
                best_similarity = similarity[repr]
            end
        end
        value = weight * best_similarity
        results[Arc(state, best_repr, value)] = state
    end

    return results
end

# For relaxation:
#  - Merge states by intersection.
merge = intersect
#  - Keep smallest states.
sort_by(pair) = length(tuple.first)

relax(max_width) = Diderot.RelaxAllInOne(max_width, intersect, sort_by)

end
