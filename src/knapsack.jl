### Knapsack Model

struct Instance
    values::Vector{Float64}
    weights::Vector{Int}
    capacity::Int
end

struct State
    capacity::Int
end

struct Infeasible end

struct Transition
    state::State
    value::Float64
end

function variables(instance::Instance)
    return 1:length(instance.values)
end

function initial_state(instance::Instance)
    return State(instance.capacity)
end

function transition(instance::Instance, state::State, variable::Int, decision::Bool)
    if decision
        slack = state.capacity - instance.weights[variable]
        if slack >= 0
            return Transition(State(slack), instance.values[variable])
        else
            return Infeasible()
        end
    else
        return Transition(state, 0.0)
    end
end

### Decision Diagram Implementation

struct Node
    layer::Int
    state::State
end

struct Arc
    tail::Node
    decision::Bool
    value::Float64
end

struct DecisionDiagram
    layers::Vector{Set{Node}}
    inarc::Dict{Node, Arc}
    distance::Dict{Node, Float64}

    function DecisionDiagram()
        return new(Vector(), Dict(), Dict())
    end
end

function top_down(instance)
    dd = DecisionDiagram()

    # Root node
    root = Node(1, initial_state(instance))
    push!(dd.layers, Set([root]))
    dd.distance[root] = 0.0

    # Intermediate layers
    for (last_layer, variable) in enumerate(variables(instance))
        current_layer = last_layer + 1
        layer = Set{Node}([])

        # Collect new states, keep only "best" arcs.
        for node in dd.layers[last_layer]
            for decision in (false, true)
                next = transition(instance, node.state, variable, decision)
                next === Infeasible() && continue

                arc = Arc(node, decision, next.value)
                new_node = Node(current_layer, next.state)
                new_distance = dd.distance[node] + arc.value
                if new_node in layer
                    if new_distance > dd.distance[new_node]
                        # Improvement in longest path!
                        dd.inarc[new_node] = arc
                        dd.distance[new_node] = new_distance
                    end
                else
                    push!(layer, new_node)
                    dd.inarc[new_node] = arc
                    dd.distance[new_node] = new_distance
                end
            end
        end

        push!(dd.layers, layer)
    end

    # Terminal node (last layer reduced to best)
    terminal = first(dd.layers[end])
    for node in dd.layers[end]
        if dd.distance[node] > dd.distance[terminal]
            terminal = node
        end
    end
    dd.layers[end] = Set([terminal])

    return dd
end

struct Solution
    decisions::Vector{Bool}
    objective::Float64
end

function longest_path(dd::DecisionDiagram)
    # Collect path in reverse, from terminal to root.
    terminal = only(dd.layers[end])
    root = only(dd.layers[1])
    node, decisions = terminal, []
    while node != root
        arc = dd.inarc[node]
        pushfirst!(decisions, arc.decision)
        node = arc.tail
    end

    return Solution(decisions, dd.distance[terminal])
end
