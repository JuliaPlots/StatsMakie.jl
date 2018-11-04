to_function(col, scale) = scale
function to_function(col, scale::AbstractArray)
    vals = unique(col)
    value2index = Dict(zip(vals, 1:length(vals)))
    t -> scale[value2index[t] % length(scale) + 1]
end

struct Group
    columns::NamedTuple
    scales::Dict{Symbol, Any}
end

function Group(args::NamedTuple)
    columns = map(t -> isa(t, Pair) ? first(t) : t, args)
    scales = Dict{Symbol, Any}(
        key => last(val) for (key, val) in pairs(args) if val isa Pair
    )
    Group(columns, scales)
end

Group(v) = Group(color = v)
Group(; kwargs...) = Group(values(kwargs))
Group(scales::AbstractDict; kwargs...) = Group(scales, values(kwargs))

IndexedTables.columns(grp::Group) = grp.columns
IndexedTables.colnames(grp::Group) = propertynames(columns(grp))

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns), merge(g1.scales, g2.scales))
Base.:*(g1::Group, g2::Group) = merge(g1, g2)

Base.length(grp::Group) = length(grp.columns[1])

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

convert_arguments(P::Type{<:AbstractPlot}, g1::Group, g2::Group, args...) =
    convert_arguments(P, merge(g1, g2), args...)

function _apply_grouping!(p::Combined{T, <: Tuple{Group, Vararg{<:Any, N}}}, g, args...) where {T, N}
    names = colnames(g)
    cols = columns(g)
    len = length(g)
    scales = map(key -> get(() -> default_scales[key], g.scales, key), names)

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
