"""
    initial_state(instance)

Initial state for a given instance (used for root node).
"""
function initial_state end

"""
    domain_type(instance)

The type used as domain for the decision variables.
"""
function domain_type end

"""
    value_type(instance)

The (numeric) type used in the objective function.
"""
function value_type end

"""
    next_variable(instance, diagram::Diagram{S,D,V}, variable_order)::Int

The variable to build the next layer, as an integer index.

Optional: Defaults to order `1:length(instance)`.

Multiple strategies can be implemented for an instance type by defining and
passing objects as `variable_order`.

The (work-in-progress) diagram is also passed and can be queried about already
assigned variables or the nodes & states of the last layer.
"""
function next_variable end

"""
    transitions(instance, state, variable::Int)::Dict{Arc{S,D,V},S}

All feasible transitions from the given state by any assignment in the
variable's domain.

Arcs specify the original state, the variable assignment and the contribution
the objective and are mapped to the new state.
"""
function transitions end

"""
    process(processing, layer::Layer{S,D,V})::Layer{S,D,V}

Build a new layer by processing the nodes of the given layer.

For restrictions, this could mean simply selecting a subset of the nodes, to
stay within the width limit.

For relaxations, new nodes are created by merging existing nodes (and setting
`exact=false`).

Optional: Defaults to `identity`.
"""
function process end
