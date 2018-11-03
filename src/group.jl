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
Group(v) = Group(:color => v)
Group(; kwargs...) = Group(kwargs...)

Base.pairs(g::Group) = g.pairs

_split(v, len, idxs) = v
_split(v::AbstractVector, len, idxs) = length(v) == len ? view(v, idxs) : v
_typ(::AbstractVector) = AbstractVector
_typ(::T) where {T} = T

function plot!(p::Combined{T, <: Tuple{Group, Vararg{<:Any, N}}}) where {T, N}
    g = p[1] |> to_value |> pairs
    names = Tuple(a for (a, b) in g)
    cols = Tuple(_first(b) for (a, b) in g)
    len = length(cols[1])

    funcs = Tuple(to_function(b) for (a, b) in g)
    coltable = table(1:len, cols..., to_value.(p[2:(N+1)])...; names = [:row, names..., (Symbol("x$i") for i in 1:N)...])
    groupby(coltable, names, usekey = true) do key, dd
        attr = copy(Theme(p))
        idxs = column(dd, :row)
        for (key, val) in attr
            attr[key] = lift(t -> _split(t, len, idxs), val, typ = _typ(val[]))
        end
        for (i, (k, v)) in enumerate(pairs(key))
            attr[k] = lift(funcs[i], to_node(v))
        end
        plot!(p, Combined{T}, attr, columns(dd, Not(:row))...)
    end
end
