### Knapsack Model

struct Instance
    values::Float64
    weights::Int
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

struct Model
    variables   # static order!
    initial     # state
    transition
end

function Model(instance::Instance)
    function variables()
        return 1:length(instance)
    end

    function initial()
        return State(instance.capacity)
    end
    
    function transition(state::State, variable::Int, decision::Bool)
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

    return Model(variables, initial, transition)
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

    # on-the-fly shortest path
    # distance::Dict{Node, Float64}
    # predecessor::Dict{Node, Node}

    function DecisionDiagram()
        return new(Vector(), Dict())
    end
end

function topdown(model)
    dd = DecisionDiagram()

    # Root node
    root = Node(1, model.initial())
    push!(dd.layers, [root])

    # Intermediate layers
    for last_layer, variable in enumerate(model.variables())
        current_layer = last_layer + 1
        layer = Set{Node}([])

        for node in dd.layers[last_layer]
            for decision in (false, true)
                next = model.transition(node.state, variable, decision)
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

    # Terminal node
    # TODO: Merge all states from last layer

    return dd
end
