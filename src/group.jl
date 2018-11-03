_first(p::Pair) = first(p)
_first(x) = x

to_function(p::Pair) = last(p)
function to_function(p::Pair{<:Any, <:AbstractArray})
    vals, cvals = p
    unique_vals = unique(vals)
    value2index = Dict(zip(unique_vals, 1:length(unique_vals)))
    t -> cvals[value2index[t] % length(cvals) + 1]
end

struct Group{N<:NTuple{<:Any, Pair}}
    pairs::N
end

completepair(p::Pair, last::Pair) = p
completepair(p::Pair, last) = first(p) => last => scale_dict[first(p)]
completepair(p::Pair) = completepair(p, last(p))

Group(args::Pair...) = Group(map(completepair, args))

Group(; kwargs...) = Group(kwargs...)

Base.pairs(g::Group) = g.pairs

function plot!(p::Combined{T, <: Tuple{Group, Vararg{<:Any, N}}}) where {T, N}
    g = p[1] |> to_value |> pairs
    names = Tuple(a for (a, b) in g)
    cols = Tuple(_first(b) for (a, b) in g)
    funcs = Tuple(to_function(b) for (a, b) in g)
    coltable = table(cols..., to_value.(p[2:(N+1)])...; names = [names..., (Symbol("x$i") for i in 1:N)...])
    groupby(coltable, names, usekey = true) do key, dd
        attr = copy(Theme(p))
        for (i, (k, v)) in enumerate(pairs(key))
            attr[k] = lift(funcs[i], to_node(v))
        end
        plot!(p, Combined{T}, attr, columns(dd)...)
    end
end
