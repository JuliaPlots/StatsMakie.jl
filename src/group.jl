struct UniqueValues{S, T1<:AbstractArray{S}, T2<:AbstractArray{S}}
    values::T1
    unique::T2
    value2index::Dict{S, Int}
end

function UniqueValues(col, s = unique(sort(col)))
    value2index = Dict(zip(s, 1:length(s)))
    UniqueValues(col, s, value2index)
end

(cs::UniqueValues)(scale::Function, el) = scale(el)

function (cs::UniqueValues)(scale::AbstractArray, el)
    scale[cs.value2index[el] % length(scale) + 1]
end

struct Group
    columns::NamedTuple
end

Group(v) = Group(color = v)
Group(; kwargs...) = Group(values(kwargs))

IndexedTables.columns(grp::Group) = grp.columns
IndexedTables.colnames(grp::Group) = propertynames(columns(grp))

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns))
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
    funcs = map(UniqueValues, cols)
    scales = map(key -> getscale(p, key), names)
    coltable = table(1:len, cols..., args...;
        names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)

    groupby(coltable, names, usekey = true) do key, dd
        attr = copy(Theme(p))
        idxs = column(dd, :row)
        for (key, val) in attr
            attr[key] = lift(t -> _split(t, len, idxs), val, typ = _typ(val[]))
        end
        for (i, (k, v)) in enumerate(pairs(key))
            attr[k] = lift(funcs[i], scales[i], to_node(v))
        end
        plot!(p, Combined{T}, attr, columns(dd, Not(:row))...)
    end
end
