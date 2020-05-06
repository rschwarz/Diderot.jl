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

function fixed_vars(dd)
    return vcat(dd.partial_sol, dd.variables)
end

function add_transition(layer, new_state, new_node)
    if haskey(layer, new_state)
        if new_node.dist > layer[new_state].dist
            layer[new_state] = new_node
        end
    else
        layer[new_state] = new_node
    end
end

function build_layer(instance, dd::DecisionDiagram{S,D,V}, variable) where {S,D,V}
    layer = Layer{S,D,V}()

    # Collect new states, keep only "best" arcs.
    for (state, node) in dd.layers[end]
        for (arc, new_state) in transitions(instance, state, variable)
            new_node = Node{S,D,V}(node.dist + arc.value, arc)
            add_transition(layer, new_state, new_node)
        end
    end

    return layer
end

# TODO: make var_order optional
function top_down!(dd::DecisionDiagram{S,D,V}, instance, var_order;
                   process_layer=identity) where {S,D,V}
    @assert length(dd.layers) == 1   # root layer

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
    maxstate, maxnode = nothing, Node{S,D,V}(typemin(V))
    for (state, node) in dd.layers[end]
        if node.dist > maxnode.dist
            maxstate = state
            maxnode = node
        end
    end
    dd.layers[end] = Layer{S,D,V}(maxstate => maxnode)
end

function longest_path(dd::DecisionDiagram{S,D,V}) where {S,D,V}
    # Collect path in reverse, from terminal to root.
    terminal = only(values(dd.layers[end]))
    num_vars =  length(dd.partial_sol) + length(dd.variables)
    decisions = Vector{D}(undef, num_vars)
    node, depth = terminal, length(dd.layers) - 1
    while depth != 0
        decisions[dd.variables[depth]] = node.inarc.decision
        state = node.inarc.tail
        node = dd.layers[depth][state]
        depth -= 1
    end

    return Solution(decisions, terminal.dist)
end

function last_exact_layer(dd)
    for (l, layer) in enumerate(dd.layers)
        if !all(node -> node.exact, values(layer))
            # Current layer has at least one relaxed node.
            @assert l > 1

            # Return previous layer (all exact)
            return l - 1
        end
    end
    # If we reached the end then even the terminal layer is exact.
    return len(dd.layers)
end

# TODO: better way to pass type parameters?
# TODO: pass solver object to store options, statistics, results?
function branch_and_bound(inst, var_order, restrict, relax)
    state = initial_state(inst)
    S = typeof(state)
    D = domain_type(inst)
    V = value_type(inst)
    orig_prob = SubProblem(Int[], D[], zero(V), state)

    problems = [orig_prob] # TODO: use priority queue
    incumbent = Solution(D[], typemin(V))
    dualbound = typemax(V)

    # Solve subproblems, one at a time.
    while !isempty(problems)
        current = popfirst!(problems)

        root_layer = Layer{S,D,V}(current.state => Node{S,D,V}(current.dist))

        # solve restriction
        dd = DecisionDiagram{S,D,V}(current.vars, [root_layer], [])
        top_down!(dd, inst, var_order, process_layer=restrict)
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
        dd = DecisionDiagram{S,D,V}(current.vars, [root_layer], [])
        top_down!(dd, inst, var_order, process_layer=relax)
        sol = longest_path(dd)

        # create subproblems if not pruned
        if sol.objective > incumbent.objective
            cutset = last_exact_layer(dd)
            @assert length(dd.layers[cutset]) > 1
            for (sub_state, sub_node) in dd.layers[cutset]
                depth = cutset - 1
                new_decs = Vector{D}(undef, depth)
                node = sub_node
                while depth != 0
                    new_decs[depth] = node.inarc.decision
                    state = node.inarc.tail
                    node = dd.layers[depth][state]
                    depth -= 1
                end

                vars = vcat(current.vars, dd.variables[1:cutset - 1])
                decs = vcat(current.decs, new_decs)

                prob = SubProblem(vars, decs, sub_node.dist, sub_state)
                push!(problems, prob)
            end
        end
    end

    return incumbent
end
