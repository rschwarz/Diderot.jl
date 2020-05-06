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
domain_type(instance::Instance) = Bool
value_type(instance::Instance) = Float64

struct State
    capacity::Int
end

function initial_state(instance::Instance)
    return State(instance.capacity)
end

struct InOrder end

function next_variable(inst, dd, ::InOrder)
    n = length(inst)
    fixed = fixed_vars(dd)
    for i in 1:n
        if !(i in fixed)  # TODO: efficient!
            return i
        end
    end
    return nothing
end

struct ByWeightDecr end

function next_variable(inst, dd, ::ByWeightDecr)
    n = length(inst)
    fixed = fixed_vars(dd)
    # TODO: efficient!
    perm = sortperm(1:length(inst), by=i->inst.weights[i], rev=true)
    for i in perm
        if !(i in fixed)
            return i
        end
    end
    return nothing
end

function transitions(instance::Instance, state, variable)
    results = Dict{Arc{State, Bool, Float64}, State}()

    # true
    slack = state.capacity - instance.weights[variable]
    if slack >= 0
        arc = Arc(state, true, instance.values[variable])
        results[arc] = State(slack)
    end

    # false
    results[Arc(state, false, 0.0)] = state # unchanged

    return results
end

### Restriction

struct RestrictLowDist
    maxwidth::Int
end

function (r::RestrictLowDist)(layer::Layer{S,D,V}) where {S,D,V}
    if length(layer) <= r.maxwidth
        return layer
    end

    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.second.dist, rev=true)
    return Layer{S,D,V}(candidates[1:r.maxwidth])
end

### Relaxation

struct RelaxLowCap
    maxwidth::Int
end

function (r::RelaxLowCap)(layer::Layer{S,D,V}) where {S,D,V}
    if length(layer) <= r.maxwidth
        return layer
    end

    # sort states by decreasing capacity
    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.first.capacity, rev=true)

    # keep first (width - 1) unchanged
    new_layer = Layer{S,D,V}(candidates[1:(r.maxwidth - 1)])

    # merge the rest:
    # - use largest capacity
    # - use predecessor for longest distance
    #   ==> does not keep all solutions!
    rest = @view candidates[r.maxwidth:end]
    merged_state = rest[1].first
    idx = argmax(map(tup -> tup.second.dist, rest))
    merged_node = rest[idx].second
    new_layer[merged_state] = Node{S,D,V}(merged_node.dist, merged_node.inarc, false)

    return new_layer
end
