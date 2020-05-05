### Knapsack Model

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

function transitions(instance::Instance, state::State, variable::Int)
    results = Dict{Arc, State}()

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

### Decision Diagram Implementation

struct Arc
    tail::State
    decision::Bool
    value::Float64
end

struct Node
    inarc::Union{Arc, Nothing}
    dist::Float64
    exact::Bool
end
Node(inarc, dist) = Node(inarc, dist, true)
Node() = Node(nothing, 0.0, true)

const Layer = Dict{State,Node}

struct DecisionDiagram
    partial_sol::Vector{Int} # partial solution

    layers::Vector{Layer}  # length n + 1
    variables::Vector{Int} # length n
end
DecisionDiagram() = DecisionDiagram([], [], [])

function Base.show(io::IO, dd::DecisionDiagram)
    println(io, "already fixed: ", dd.partial_sol)
    println(io, "root: ", only(dd.layers[1]))
    for (l, var) in enumerate(dd.variables)
        println(io, "var: ", var)
        for tup in dd.layers[l + 1]
            println(io, " ", tup)
        end
    end
end

function fixed_vars(dd::DecisionDiagram)
    return vcat(dd.partial_sol, dd.variables)
end

function add_transition(layer::Layer, new_state::State, new_node::Node)
    if haskey(layer, new_state)
        if new_node.dist > layer[new_state].dist
            layer[new_state] = new_node
        end
    else
        layer[new_state] = new_node
    end
end

function build_layer(instance, dd, variable)
    layer = Layer()

    # Collect new states, keep only "best" arcs.
    for (state, node) in dd.layers[end]
        for (arc, new_state) in transitions(instance, state, variable)
            new_node = Node(arc, node.dist + arc.value)
            add_transition(layer, new_state, new_node)
        end
    end

    return layer
end

function top_down(instance, var_order;
                  process_layer=identity,
                  dd=DecisionDiagram())
    # Add root layer if missing
    if length(dd.layers) == 0
        root = Layer(initial_state(instance) => Node())
        push!(dd.layers, root)
    end

    # Intermediate layers

    while true
        variable = next_variable(instance, dd, var_order)
        if variable === nothing
            break
        end

        layer = build_layer(instance, dd, variable)
        layer = process_layer(layer)   # restrict/relax

        push!(dd.layers, layer)
        push!(dd.variables, variable)
    end

    # Terminal node (last layer reduced to best)
    maxstate, maxnode = nothing, Node(nothing, -Inf)
    for (state, node) in dd.layers[end]
        if node.dist > maxnode.dist
            maxstate = state
            maxnode = node
        end
    end
    dd.layers[end] = Dict(maxstate => maxnode)

    return dd
end

struct Solution
    decisions::Vector{Bool}
    objective::Float64
end

function longest_path(dd::DecisionDiagram)
    # Collect path in reverse, from terminal to root.
    terminal = only(values(dd.layers[end]))
    decisions = Vector{Bool}(undef, length(dd.variables))
    node, depth = terminal, length(dd.layers) - 1
    while depth != 0
        decisions[dd.variables[depth]] = node.inarc.decision
        state = node.inarc.tail
        node = dd.layers[depth][state]
        depth -= 1
    end

    return Solution(decisions, terminal.dist)
end

### Restriction

struct RestrictLowDist
    maxwidth::Int
end

function (r::RestrictLowDist)(layer::Layer)
    if length(layer) <= r.maxwidth
        return layer
    end

    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.second.dist, rev=true)
    return Layer(candidates[1:r.maxwidth])
end

### Relaxation

struct RelaxLowCap
    maxwidth::Int
end

function (r::RelaxLowCap)(layer::Layer)
    if length(layer) <= r.maxwidth
        return layer
    end

    # sort states by decreasing capacity
    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.first.capacity, rev=true)

    # keep first (width - 1) unchanged
    new_layer = Layer(candidates[1:(r.maxwidth - 1)])

    # merge the rest:
    # - use largest capacity
    # - use predecessor for longest distance
    #   ==> does not keep all solutions!
    rest = @view candidates[r.maxwidth:end]
    merged_state = rest[1].first
    idx = argmax(map(tup -> tup.second.dist, rest))
    merged_node = rest[idx].second
    new_layer[merged_state] = Node(merged_node.inarc, merged_node.dist, false)

    return new_layer
end

### Branch-and-Bound

struct SubProblem
    # partial solution (assigned so far)
    vars::Array{Int}
    decs::Array{Bool}
    dist::Float64

    # state (to complete solution)
    state::State
end

function last_exact_layer(dd::DecisionDiagram)
    for (l, layer) in enumerate(dd.layers)
        if !all((s,n) -> n.exact, layer)
            # Current layer has at least one relaxed node.
            @assert l > 1

            # Return previous layer (all exact)
            return l - 1
        end
    end
    # If we reached the end then even the terminal layer is exact.
    return len(dd.layers)
end

function branch_and_bound(inst, variter, restrict, relax)
    problems = [] # TODO: use priority queue?
    incumbent = Solution([], -Inf)
    dualbound = Inf

    # Set up original problem
    push!(problems, SubProblem([], [], 0.0, initial_state(inst)))

    # Solve subproblems, one at a time.
    while !empty(problems)
        current = popfirst!(problems)

        # TODO: tell variter about partial sol!

        root_layer = Layer(current.state => Node(nothing, current.dist, true))

        # solve restriction
        dd = DecisionDiagram(root_layer, [])
        top_down(inst, variter, process_layer=restrict, dd=dd)
        sol = longest_path(dd)

        # update incumbent
        if sol.objective > incumbent.objective
            for (var, dec) in zip(current.vars, current.decs)
                sol.decisions[var] = dec
            end
            incumbent = sol
        end

        # TODO: check if restriction was exact (then continue)

        # solve relaxation
        dd = DecisionDiagram(root_layer, [])
        top_down(inst, variter, process_layer=restrict, dd=dd)
        sol = longest_path(dd)

        # create subproblems if not pruned
        if sol.objective > incumbent.objective
            cutset = last_exact_layer(dd)
            for (sub_state, sub_node) in dd.layers[cutset]
                depth = cutset - 1
                new_decs = Vector{Bool}(undef, depth)
                while depth != 0
                    new_decs[depth] = node.inarc.decision
                    state = node.inarc.tail
                    node = dd.layers[depth][state]
                    depth -= 1
                end

                vars = vcat(current.vars, dd.variables[1:depth])
                decs = vcat(current.decs, new_decs)

                prob = SubProblem(vars, decs, sub_node.dist, sub_state)
                push!(problems, prob)
            end
        end
    end

end
