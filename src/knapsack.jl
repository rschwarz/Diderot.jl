module Knapsack

using ..Diderot
using ..Diderot: Arc, Node, Layer

struct Instance
    values::Vector{Float64}
    weights::Vector{Int}
    capacity::Int

    function Instance(values, weights, capacity)
        @assert length(values) == length(weights)
        new(values, weights, capacity)
    end
end

Base.length(instance::Instance) = length(instance.values)
Diderot.domain_type(instance::Instance) = Bool
Diderot.value_type(instance::Instance) = Float64

Diderot.initial_state(instance::Instance) = instance.capacity

struct DecreasingWeight end

function Diderot.next_variable(instance, diagram, ::DecreasingWeight)
    n = length(instance)
    fixed = Diderot.fixed_variables(diagram)
    # TODO: efficient!
    perm = sortperm(1:n, by=i->instance.weights[i], rev=true)
    for i in perm
        if !(i in fixed)
            return i
        end
    end
    return nothing
end

function Diderot.transitions(instance::Instance, state, variable)
    results = Dict{Arc{Int, Bool, Float64}, Int}()

    # true
    slack = state - instance.weights[variable]
    if slack >= 0
        arc = Arc(state, true, instance.values[variable])
        results[arc] = slack
    end

    # false
    results[Arc(state, false, 0.0)] = state # unchanged

    return results
end

### Relaxation

# For relaxation:
# - Keep states with largest remaining capacity.
# - Merge states by maximum value.
sort_by(tuple) = -tuple.first
merge = max
relax(max_width) = Diderot.RelaxAllInOne(max_width, merge, sort_by)

end # module
