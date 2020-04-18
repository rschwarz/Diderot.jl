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

struct Arc
    tail::State
    decision::Bool
    value::Float64
end

struct Node
    inarc::Union{Arc, Nothing}
    dist::Float64
end
Node() = Node(nothing, 0.0)

const Layer = Dict{State,Node}

struct DecisionDiagram
    layers::Vector{Layer}
    variables::Vector{Int}
end
DecisionDiagram() = DecisionDiagram([], [])

function top_down(instance)
    dd = DecisionDiagram()
    root = Layer(initial_state(instance) => Node())
    push!(dd.layers, root)

    # Intermediate layers
    for (depth, variable) in enumerate(variables(instance))
        layer = Layer()

        # Collect new states, keep only "best" arcs.
        for (state, node) in dd.layers[end]
            for decision in (false, true)
                next = transition(instance, state, variable, decision)
                next === Infeasible() && continue

                arc = Arc(state, decision, next.value)
                new_node = Node(arc, node.dist + arc.value)
                if haskey(layer, next.state)
                    if new_node.dist > layer[next.state].dist
                        layer[next.state] = new_node
                    end
                else
                    layer[next.state] = new_node
                end
            end
        end

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
