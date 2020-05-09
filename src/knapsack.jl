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

### Restriction

struct RestrictLowDistance
    max_width::Int
end

function Diderot.process(
    restrict::RestrictLowDistance, layer::Layer{S,D,V}
) where {S,D,V}
    if length(layer) <= restrict.max_width
        return layer
    end

    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.second.distance, rev=true)
    return Layer{S,D,V}(Dict(candidates[1:restrict.max_width]), false)
end

### Relaxation

struct RelaxLowCapacity
    max_width::Int
end

function Diderot.process(
    relax::RelaxLowCapacity, layer::Layer{S,D,V}
) where {S,D,V}
    if length(layer) <= relax.max_width
        return layer
    end

    # sort states by decreasing capacity
    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.first, rev=true)

    # keep first (width - 1) unchanged
    new_layer = Layer{S,D,V}(Dict(candidates[1:(relax.max_width - 1)]), false)

    # merge the rest:
    # - use largest capacity
    # - use predecessor for longest distance
    #   ==> does not keep all solutions!
    rest = @view candidates[relax.max_width:end]
    merged_state = rest[1].first
    index = argmax(map(pair -> pair.second.distance, rest))
    merged_node = rest[index].second
    new_node = Node{S,D,V}(merged_node.distance, merged_node.inarc, false)
    new_layer[merged_state] = new_node

    return new_layer
end

end # module
