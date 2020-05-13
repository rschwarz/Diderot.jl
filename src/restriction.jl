struct RestrictLowDistance
    max_width::Int
end

function Diderot.process(
    restrict::RestrictLowDistance, layer::Layer{S,D,V}
) where {S,D,V}
    if length(layer) <= restrict.max_width
        return layer
    end

    candidates = collect(layer)
    sort!(candidates, by=tup -> tup.second.distance, rev=true)
    return Layer{S,D,V}(Dict(candidates[1:restrict.max_width]), false)
end
