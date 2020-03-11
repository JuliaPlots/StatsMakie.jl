is_scale(::FunctionOrAnalysis) = true
is_scale(::AbstractArray) = true
is_scale(::Any) = false

function compute_attribute(scale::FunctionOrAnalysis, el, rank_dict)
    scale(el)
end
function compute_attribute(scale::AbstractArray, el, rank_dict)
    scale[mod1(rank_dict[el], length(scale))]
end

function rank_dict(col::AbstractVector)
    s = collect(uniquesorted(col))
    return Dict(zip(s, 1:length(s)))
end
