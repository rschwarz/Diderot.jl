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

function terminal_state(instance::Instance)
    return State(-1)
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
    inarcs::Dict{Node, Vector{Arc}}

    function DecisionDiagram()
        return new(Vector(), Dict())
    end
end

function top_down(instance)
    dd = DecisionDiagram()

    # Root node
    root = Node(1, initial_state(instance))
    push!(dd.layers, Set([root]))

    # Intermediate layers
    for (last_layer, variable) in enumerate(variables(instance))
        current_layer = last_layer + 1
        layer = Set{Node}([])

        for node in dd.layers[last_layer]
            for decision in (false, true)
                next = transition(instance, node.state, variable, decision)
                next === Infeasible() && continue

                new_node = Node(current_layer, next.state)
                push!(layer, new_node)

                arc = Arc(node, decision, next.value)
                inarcs = get!(dd.inarcs, new_node, Arc[])
                push!(inarcs, arc)
            end
        end

        push!(dd.layers, layer)
    end

    # Terminal node (last layer merged to one)
    terminal = Node(length(dd.layers), terminal_state(instance))
    inarcs = Arc[]
    for node in dd.layers[end]
        append!(inarcs, dd.inarcs[node])
        delete!(dd.inarcs, node)
    end
    dd.inarcs[terminal] = inarcs
    dd.layers[end] = Set([terminal])

    return dd
end

struct Solution
    decisions::Vector{Bool}
    objective::Float64
end

function longest_path(dd::DecisionDiagram)
    distance = Dict{Node, Float64}()
    predecessor = Dict{Node, Arc}()

    # Start from root, find path to terminal.
    root = only(dd.layers[1])
    distance[root] = 0.0

    # Search layer by layer.
    for layer in dd.layers[2:end]
        for node in layer
            @assert node ∉ distance && node ∉ predecessor
            dist, pred = Inf, nothing
            for arc in dd.inarcs[node]
                newdist = distance[arc.tail] + arc.value
                if newdist > dist
                    dist = newdist
                    pred = arc
                end
            end
            distance[node] = dist
            predecessor[node] = pred
        end
    end

    # Collect path in reverse, from terminal.
    terminal = only(dd.layers[end])
    node, decisions = terminal, []
    while node != root
        arc = pred[node]
        pushfirst![decisions, arc.decision]
        node = arc.tail
    end

    return Solution(decision, distance[terminal])
end
