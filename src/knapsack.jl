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

    return Model(initial, transition)
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

    function DecisionDiagram(initial)
        root = Node(0, initial)
        return new(Set[root], Dict())
    end
end

function topdown(model)
    dd = DecisionDiagram(model.initial())
    # TODO
end
