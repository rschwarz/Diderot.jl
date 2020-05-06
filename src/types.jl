# type parameters:
#
# S: state
# D: domain, for variables
# V: value, for objective

struct Arc{S,D,V}
    tail::S
    decision::D
    value::V
end

struct Node{S,D,V}
    dist::V
    inarc::Union{Arc{S,D,V},Nothing}
    exact::Bool

    function Node{S,D,V}(dist, inarc=nothing, exact=true) where {S,D,V}
        new(dist, inarc, exact)
    end
end

const Layer{S,D,V} = Dict{S,Node{S,D,V}}

struct DecisionDiagram{S,D,V}
    partial_sol::Vector{Int}      # given & fixed

    layers::Vector{Layer{S,D,V}}  # length n + 1
    variables::Vector{Int}        # length n
end

function DecisionDiagram(root::Layer{S,D,V}) where {S,D,V}
    return DecisionDiagram{S,D,V}([], [root], [])
end

function DecisionDiagram(inst)
    state = initial_state(inst)
    S = typeof(state)
    D = domain_type(inst)
    V = value_type(inst)
    node = Node{S,D,V}(zero(V))
    root = Layer{S,D,V}(state => node)
    return DecisionDiagram(root)
end

# TODO: improve reuse between Solution and SubProblem

struct Solution{D,V}
    decisions::Vector{D}  # for all variables, order 1:n
    objective::V
end

struct SubProblem{S,D,V}
    # partial solution (assigned so far, in given order)
    vars::Array{Int}
    decs::Array{D}
    dist::V

    # state (to complete solution)
    state::S
end
