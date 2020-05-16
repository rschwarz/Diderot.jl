struct RelaxAllInOne
    max_width::Int
    merge
    sort_by  # TODO: add default implementation (distance)
end

function Diderot.process(
    relax::RelaxAllInOne, layer::Layer{S,D,V}
) where {S,D,V}
    if length(layer) <= relax.max_width
        return layer
    end

    # Sort states (best ones first).
    candidates = collect(layer)
    sort!(candidates, by=relax.sort_by)

    # Keep first (width - 1) unchanged.
    new_layer = Layer{S,D,V}(Dict(candidates[1:(relax.max_width - 1)]), false)

    # Merge the remaining states into a single relaxed state.
    rest = @view candidates[relax.max_width:end]
    merged_state = foldl(relax.merge, first.(rest))

    # Use predecessor for longest distance of any merged state.
    index = argmax(map(pair -> pair.second.distance, rest))
    merged_node = rest[index].second
    new_node = Node{S,D,V}(merged_node.distance, merged_node.inarc, false)
    new_layer[merged_state] = new_node

    return new_layer
end
