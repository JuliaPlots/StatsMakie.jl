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

struct PlottableTable{P}
    table::AbstractIndexedTable
end

struct Group
    columns::NamedTuple
    f::Function
    kwargs::Dict{Symbol, Any}
end

Group(c::NamedTuple, f::Function = tuple) = Group(c, f, Dict{Symbol, Any}())

Group(v, f::Function = tuple) = Group((color = v,), f)
Group(f::Function = tuple; kwargs...) = Group(values(kwargs), f)

IndexedTables.columns(grp::Group) = grp.columns
IndexedTables.colnames(grp::Group) = propertynames(columns(grp))

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns), g2.f, g2.kwargs)
Base.:*(g1::Group, g2::Group) = merge(g1, g2)

Base.length(grp::Group) = length(grp.columns[1])

_split(v, len, idxs) = v
_split(v::AbstractVector, len, idxs) = length(v) == len ? view(v, idxs) : v
_typ(::AbstractVector) = AbstractVector
_typ(::T) where {T} = T

function default_theme(scene, ::Type{<:Combined{T, <: Tuple{PlottableTable{P}}}}) where {T, P}
    default_theme(scene, P)
end

function plot!(p::Combined{T, <: Tuple{PlottableTable}}) where {T}
    t = (p[1] |> to_value).table
    cols = columns(pkeys(t))
    names = keys(cols)
    funcs = map(UniqueValues, cols)
    scales = map(key -> getscale(p, key), names)
    len = sum(length, column(t, :rows))
    for row in rows(t)
        attr = copy(Theme(p))
        for (i, key) in enumerate(names)
            val = getproperty(row, key)
            attr[key] = lift(funcs[i], scales[i], to_node(val))
        end
        for (key, val) in attr
            (key in names) || (attr[key] = lift(t -> _split(t, len, row.rows), val, typ = _typ(val[])))
        end
        out = row.output
        (P, args) = out isa Pair ? out : (Combined{T}, out)
        plot!(p, P, attr, args...)
    end
end

to_tuple(t::Tuple) = t
to_tuple(t) = (t,)


convert_arguments(P::PlotFunc, g1::Group, g2::Group, args...; kwargs...) =
    convert_arguments(P, merge(g1, g2), args...; kwargs...)

convert_arguments(P::PlotFunc, f::Function, g1::Group, g2::Group, args...; kwargs...) =
    convert_arguments(P, f, merge(g1, g2), args...; kwargs...)

convert_arguments(P::PlotFunc, f::Function, g::Group, args...; kwargs...) =
    convert_arguments(P, Group(g.columns, f, kwargs), args...)

function convert_arguments(P::PlotFunc, g::Group, args...; kwargs...)
    merge!(g.kwargs, Dict(kwargs))
    N = length(args)
    f = g.f
    names = colnames(g)
    cols = columns(g)
    len = length(g)
    funcs = map(UniqueValues, cols)
    coltable = table(1:len, cols..., args...;
        names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)

    t = groupby(coltable, names, usekey = true) do key, dd
        idxs = column(dd, :row)
        tup = (rows = idxs, output = convert_arguments(P, to_tuple(f(columns(dd, Not(:row))...))...),)
    end
    P = first(t[1].output)
    (PlottableTable{P}(t), )
end
