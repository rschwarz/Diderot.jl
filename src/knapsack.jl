module Knapsack
using ..Diderot
const DD = Diderot

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

struct InOrder end

function Diderot.next_variable(inst, dd, ::InOrder)
    n = length(inst)
    fixed = Diderot.fixed_vars(dd)
    for i in 1:n
        if !(i in fixed)  # TODO: efficient!
            return i
        end
    end
    return nothing
end

struct ByWeightDecr end

function Diderot.next_variable(inst, dd, ::ByWeightDecr)
    n = length(inst)
    fixed = Diderot.fixed_vars(dd)
    # TODO: efficient!
    perm = sortperm(1:length(inst), by=i->inst.weights[i], rev=true)
    for i in perm
        if !(i in fixed)
            return i
        end
    end
    return nothing
end

function Diderot.transitions(instance::Instance, state, variable)
    results = Dict{DD.Arc{Int, Bool, Float64}, Int}()

    # true
    slack = state - instance.weights[variable]
    if slack >= 0
        arc = DD.Arc(state, true, instance.values[variable])
        results[arc] = slack
    end

    # false
    results[DD.Arc(state, false, 0.0)] = state # unchanged

    return results
end

### Restriction

struct RestrictLowDist
    maxwidth::Int
end

function (r::RestrictLowDist)(layer::DD.Layer{S,D,V}) where {S,D,V}
    if length(layer) <= r.maxwidth
        return layer
    end

    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.second.dist, rev=true)
    return DD.Layer{S,D,V}(candidates[1:r.maxwidth])
end

### Relaxation

struct RelaxLowCap
    maxwidth::Int
end

function (r::RelaxLowCap)(layer::DD.Layer{S,D,V}) where {S,D,V}
    if length(layer) <= r.maxwidth
        return layer
    end

    # sort states by decreasing capacity
    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.first, rev=true)

    # keep first (width - 1) unchanged
    new_layer = DD.Layer{S,D,V}(candidates[1:(r.maxwidth - 1)])

    # merge the rest:
    # - use largest capacity
    # - use predecessor for longest distance
    #   ==> does not keep all solutions!
    rest = @view candidates[r.maxwidth:end]
    merged_state = rest[1].first
    idx = argmax(map(tup -> tup.second.dist, rest))
    merged_node = rest[idx].second
    new_layer[merged_state] = DD.Node{S,D,V}(merged_node.dist, merged_node.inarc, false)

    return new_layer
end

end # module
