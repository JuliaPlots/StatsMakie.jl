_first(p::Pair) = first(p)
_first(x) = x

to_function(p::Pair) = last(p)
function to_function(p::Pair{<:Any, <:AbstractArray})
    ls = unique(first(p))
    value2index = Dict(zip(ls, 1:length(ls)))
    t -> last(p)[value2index[t]]
end

function plot!(scene::SceneLike, ::Type{T}, attributes::Attributes, g::NTuple{<:Any, Pair}, p...) where {T<:AbstractPlot}
    names = Tuple(a for (a, b) in g)
    cols = Tuple(_first(b) for (a, b) in g)
    funcs = Tuple(to_function(b) for (a, b) in g)
    coltable = table(cols..., p...; names = [names..., (Symbol("x$i") for i in 1:length(p))...])
    groupby(coltable, names, usekey = true) do key, dd
        attr = copy(attributes)
        for (i, (k, v)) in enumerate(pairs(key))
            attr[k] = Signal(funcs[i](v))
            plot!(scene, T, attr, columns(dd)...)
        end
    end
    scene
end
