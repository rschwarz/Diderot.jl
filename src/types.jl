using AutoHashEquals

# The type parameters specify the (user-defined)
#   S: state
#   D: variable domain
#   V: objective value


"""
    Arc{S,D,V}

An arc in the decision diagram, representing a state transition.

It points to the original/previous state and also stores the decision made
(variable assignment) as well as the contribution to the objective function.
"""
@auto_hash_equals struct Arc{S,D,V}
    tail::S
    decision::D
    value::V
end

"""
    Node{S,D,V}

Meta-data for a node in the decision diagram.

Stores the distance from the root node on the longest path so far, the
ingoing arc on such a path (but no other ingoing arcs) and a flag to specify
whether the state is *exact*, as opposed to *relaxed*.
"""
@auto_hash_equals struct Node{S,D,V}
    distance::V
    inarc::Union{Arc{S,D,V},Nothing}
    exact::Bool

    function Node{S,D,V}(distance, inarc=nothing, exact=true) where {S,D,V}
        new(distance, inarc, exact)
    end
end

"""
    Layer{S,D,V}

A layer of nodes in the decision diagram.

Represented by mapping from (user-defined) states to the Node meta-data. Also
has a flag `exact` to indicate whether all states are represented exactly
(neither restricted nor relaxed).
"""
@auto_hash_equals struct Layer{S,D,V}
    nodes::Dict{S,Node{S,D,V}}
    exact::Bool

    function Layer{S,D,V}(nodes=Dict(), exact=true) where {S,D,V}
        return new(nodes, exact)
    end
end

function Base.iterate(layer::Layer{S,D,V}) where {S,D,V}
    return iterate(layer.nodes)
end

function Base.iterate(layer::Layer{S,D,V}, state) where {S,D,V}
    return iterate(layer.nodes, state)
end

function Base.length(layer::Layer{S,D,V}) where {S,D,V}
    return length(layer.nodes)
end

function Base.haskey(layer::Layer{S,D,V}, state::S) where {S,D,V}
    return haskey(layer.nodes, state)
end

function Base.getindex(layer::Layer{S,D,V}, state::S) where {S,D,V}
    return getindex(layer.nodes, state)
end

function Base.setindex!(
    layer::Layer{S,D,V}, node::Node{S,D,V}, state::S
) where {S,D,V}
    return setindex!(layer.nodes, node, state)
end

"""
    Diagram{S,D,V}

A (multi-valued) decision diagram.

It's a directed acyclic graph where the nodes represent (feasible) states and
the arcs transitions triggered by decision variable assignments. Decisions are
made sequentially and arcs only connect consecutive layers. The initial layer
contains the single, given root node. All nodes in the final layer are merged to
a single terminal node.

As the variable order can be defined dynamically, the variable indices are also
stored. Note that the constructed diagram will have N+1 layers for N variables.

There is also a property `partial_sol` containing indices of variables that are
already assigned outside this diagram (in the context of branch-and-bound).
"""
@auto_hash_equals struct Diagram{S,D,V}
    partial_sol::Vector{Int}
    layers::Vector{Layer{S,D,V}}
    variables::Vector{Int}
end

function Diagram(initial::Layer{S,D,V}) where {S,D,V}
    return Diagram{S,D,V}([], [initial], [])
end

function Diagram(instance)
    state = initial_state(instance)
    S = typeof(state)
    D = domain_type(instance)
    V = value_type(instance)
    node = Node{S,D,V}(zero(V))
    root = Layer{S,D,V}(Dict(state => node))
    return Diagram(root)
end

"""
    Solution{D,V}

A feasible solution, with decisions for all variables (in order) and the
objective values.
"""
@auto_hash_equals struct Solution{D,V}
    decisions::Vector{D}  # for all variables, order 1:n
    objective::V
end

"""
    Subproblem{D,V}

A subproblem in the context of branch-and-bound, as defined by an exact node in
the diagram. It's represented by the partial solution given by a longest path
from the root that node and the current state.
"""
@auto_hash_equals struct Subproblem{S,D,V}
    # partial solution (assigned so far, in given order)
    variables::Vector{Int}
    decisions::Vector{D}
    distance::V

    # state (to complete solution)
    state::S
end
