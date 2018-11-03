_first(p::Pair) = first(p)
_first(x) = x

to_function(col, scale) = scale
function to_function(col, scale::AbstractArray)
    vals = unique(col)
    value2index = Dict(zip(vals, 1:length(vals)))
    t -> scale[value2index[t] % length(scale) + 1]
end

struct Group
    columns::Columns
    scales::Dict{Symbol, Any}
end

function Group(args::NamedTuple, sc = Dict())
    columns = Columns(map(_first, args))
    scales = Dict{Symbol, Any}(sc)
    for (key, val) in pairs(args)
        if val isa Pair
            scales[key] = last(val)
        end
    end
    Group(columns, scales)
end

Group(v::AbstractVector) = Group(color = v)
Group(sc::AbstractDict = Dict(); kwargs...) = Group(values(kwargs), sc)

IndexedTables.columns(grp::Group) = columns(grp.columns)
IndexedTables.colnames(grp::Group) = colnames(grp.columns)

Base.length(grp::Group) = length(grp.columns)

_split(v, len, idxs) = v
_split(v::AbstractVector, len, idxs) = length(v) == len ? view(v, idxs) : v
_typ(::AbstractVector) = AbstractVector
_typ(::T) where {T} = T

function plot!(p::Combined{T, <: Tuple{Group, Vararg{<:Any, N}}}) where {T, N}
    _apply_grouping!(p, to_value.(p[1:(N+1)])...)
    onany(p[1:(N+1)]...) do ps...
        len = length(ps[1])
        if all(length(col) == len for col in ps)
            empty!(p.plots)
            _apply_grouping!(p, ps...)
        end
    end
end

function _apply_grouping!(p::Combined{T, <: Tuple{Group, Vararg{<:Any, N}}}, g, args...) where {T, N}
    names = colnames(g)
    cols = columns(g)
    len = length(g)
    scales = map(key -> get(g.scales, key, scale_dict[key]), names)

    funcs = Tuple(to_function(col, scale) for (col, scale) in zip(cols, scales))
    coltable = table(1:len, cols..., args...; names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)
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
