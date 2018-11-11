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
    scale[(cs.value2index[el] - 1) % length(scale) + 1]
end

struct PlottableTable{P}
    table::AbstractIndexedTable
    attr::Dict{Symbol, Any}
end

PlottableTable{P}(t) where {P} = PlottableTable{P}(t, Dict{Symbol, Any}())

plottype(::Type{PlottableTable{T}}) where {T} = T

struct Group
    columns::NamedTuple
    f::Function
end

Group(c::NamedTuple) = Group(c, tuple)

Group(v, f::Function = tuple) = Group((color = v,), f)
Group(f::Function = tuple; kwargs...) = Group(values(kwargs), f)

IndexedTables.columns(grp::Group) = grp.columns
IndexedTables.colnames(grp::Group) = propertynames(columns(grp))

combine(f1, f2) = (args...) -> f1(to_tuple(f2(args...))...)
combine(f1, f2::typeof(tuple)) = f1
combine(f1::typeof(tuple), f2) = f2
combine(f1::typeof(tuple), f2::typeof(tuple)) = tuple

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns), combine(g1.f, g2.f))
Base.merge(f::Function, g::Group) = merge(Group(f), g)
Base.merge(g::Group, f::Function) = merge(f, g)

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
    pt = (p[1] |> to_value)
    t = pt.table
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
        for (key, val) in pt.attr
            (attr[key] = lift(t -> _split(t, len, row.rows), val, typ = _typ(val[])))
        end
        plot!(p, Combined{T}, attr, row.output...)
    end
end

to_tuple(t::Tuple) = t
to_tuple(t) = (t,)


convert_arguments(P::PlotFunc, g1::Group, g2::Group, args...; kwargs...) =
    convert_arguments(P, merge(g1, g2), args...; kwargs...)

convert_arguments(P::PlotFunc, f::Function, g1::Group, g2::Group, args...; kwargs...) =
    convert_arguments(P, f, merge(g1, g2), args...; kwargs...)

convert_arguments(P::PlotFunc, f::Function, g::Group, args...; kwargs...) =
    convert_arguments(P, merge(f, g), args...; kwargs...)

to_pair(P, t) = P => t
to_pair(P, p::Pair) = to_pair(plottype(P => first(p)), last(p))
function convert_arguments(P::PlotFunc, g::Group, args...; kwargs...)
    N = length(args)
    f = g.f
    names = colnames(g)
    cols = columns(g)
    len = length(g)
    funcs = map(UniqueValues, cols)
    coltable = table(1:len, cols..., args...;
        names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)

    PT = Ref{Any}(nothing)
    t = groupby(coltable, names, usekey = true) do key, dd
        idxs = column(dd, :row)
        out = to_tuple(f(columns(dd, Not(:row))...; kwargs...))
        pt, args = to_pair(P, convert_arguments(P, out...))
        PT[] = pt
        tup = (rows = idxs, output = args)
    end
    PT[] => (PlottableTable{PT[]}(t), )
end
