_first(p::Pair) = first(p)
_first(x) = x

to_function(p::Pair) = last(p)
function to_function(p::Pair{<:Any, <:AbstractArray})
    ls = unique(first(p))
    value2index = Dict(zip(ls, 1:length(ls)))
    t -> last(p)[value2index[t]]
end

struct Grouped{N<:NTuple{<:Any, Pair}}
    pairs::N
end

Grouped(args...) = Grouped(args)

Base.pairs(g::Grouped) = g.pairs

function plot!(p::Combined{Any, Tuple{Grouped, Vararg{N}}}) where {N}
    g = p[1] |> to_value |> pairs
    keys(p) |> println
    names = Tuple(a for (a, b) in g)
    cols = Tuple(_first(b) for (a, b) in g)
    funcs = Tuple(to_function(b) for (a, b) in g)
    coltable = table(cols..., to_value.(p[2:N])...; names = [names..., (Symbol("x$i") for i in 1:N)...])
    groupby(coltable, names, usekey = true) do key, dd
        for (i, (k, v)) in enumerate(pairs(key))
            p[k] = lift(funcs[i], v)
        end
        scatter!(p, columns(dd)...)
    end
end
