is_scale(::Function) = true
is_scale(::AbstractArray) = true
is_scale(::Any) = false

function compute_attribute(scale::Function, el, rankdict)
    scale(el)
end
function compute_attribute(scale::AbstractArray, el, rankdict)
    scale[mod1(rankdict[el], length(scale))]
end

function rankdict(col::AbstractVector)
    s = collect(uniquesorted(col))
    return Dict(zip(s, 1:length(s)))
end
