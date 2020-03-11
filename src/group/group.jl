struct Group
    columns::NamedTuple
    f::FunctionOrAnalysis
end

Group(c::NamedTuple) = Group(c, tuple)

Group(v, f::FunctionOrAnalysis = tuple) = Group((color = v,), f)
Group(f::FunctionOrAnalysis = tuple; kwargs...) = Group(values(kwargs), f)

struct ByColumn end
const bycolumn = ByColumn()

Base.isless(::ByColumn, ::ByColumn) = false

combine_gog(f1, f2) = (args...) -> f1(to_tuple(f2(args...))...)
combine_gog(f1, f2::typeof(tuple)) = f1
combine_gog(f1::typeof(tuple), f2) = f2
combine_gog(f1::typeof(tuple), f2::typeof(tuple)) = tuple

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns), combine_gog(g1.f, g2.f))
Base.merge(f::FunctionOrAnalysis, g::Group) = merge(Group(f), g)
Base.merge(g::Group, f::FunctionOrAnalysis) = merge(g, Group(f))

Base.:*(g1::Group, g2::Group) = merge(g1, g2)

width(v::Tuple) = length(v)
width(v::NamedTuple) = maximum(width, v)
width(v::AbstractVector) = 1
width(v::AbstractArray) = mapreduce(length, *, axes(v)[2:end])

column_length(v::Union{Tuple, NamedTuple}) = column_length(v[1])
column_length(v::AbstractVector) = length(v)
column_length(v::AbstractArray) = length(axes(v)[1])

extract_view(v::Union{Tuple, NamedTuple}, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)
extract_view(v::AbstractArray, idxs) = view(v, idxs, axes(v)[2:end]...)

extract_view(v::Tuple, idxs, n) = extract_view(v[n], idxs)
extract_view(v::AbstractVector, idxs, n) = view(v, idxs)
function extract_view(v::AbstractArray, idxs, n)
    ax = axes(v)[2:end]
    c = CartesianIndices(ax)[n]
    view(v, idxs, Tuple(c)...)
end

extract_view(v::NamedTuple, idxs, n) = map(t -> extract_view(t, idxs, n), v)

struct Data{T}
    table::T
end

struct Style
    args::Tuple
    kwargs::NamedTuple
    Style(args...; kwargs...) = new(args, values(kwargs))
end

to_style(s::Style) = s
to_style(x) = Style(x)

Base.merge(s1::Style, s2::Style) = Style(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)
Base.:*(s1::Style, s2::Style) = merge(s1, s2)

const GoG = Union{Data, Group, Style}

Base.merge(g1::GoG, g2::GoG) = merge(to_style(g1), to_style(g2))
Base.merge(f::FunctionOrAnalysis, s::Style) = merge(Group(f), s)
Base.merge(s::Style, f::FunctionOrAnalysis) = merge(s, Group(f))

extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, c::ByColumn) = c
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)
extract_column(t, col::AbstractArray) =
    mapslices(v -> extract_column(t, v[1]), col, dims = 1)

extract_column(t, grp::Group) = Group(extract_columns(t, grp.columns), grp.f)

extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

function extract_columns(df, st::Style)
    t = columntable(df)
    Style(
        extract_columns(t, st.args)...;
        extract_columns(t, st.kwargs)...
    )
end

to_args(st::Style) = st.args

to_kwargs(st::Style) = st.kwargs

to_function(s::Style) = to_args(s)[1].f

used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, f, args...)))

used_attributes(P::PlotFunc, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, args...)))

for typ in (:Function, :AbstractAnalysis)
    @eval function convert_arguments(P::PlotFunc, f::($typ), arg::GoG, args...; kwargs...)
        style = foldl(merge, (to_style(el) for el in args), init = to_style(arg))
        convert_arguments(P, merge(f, style); kwargs...)
    end
end

convert_arguments(P::PlotFunc, arg::GoG, args...; kwargs...) =
    convert_arguments(P, tuple, arg, args...; kwargs...)

function normalize(s::Style)
    isdata = isa.(to_args(s), Data)
    i = findfirst(isdata)
    s1 = Style(to_args(s)[findall(!, isdata)]...; to_kwargs(s)...)
    s2 = i === nothing ? s1 : extract_columns(to_args(s)[i].table, s1)

    args = Iterators.filter(t -> !(t isa Group), to_args(s2))
    g = foldl(merge, Iterators.filter(t -> t isa Group, to_args(s2)), init = Group())
    Style(g, args...; to_kwargs(s2)...)
end

struct TraceSpec{N<:NamedTuple, T<:Tuple}
    primary::N
    idxs::Vector{Int}
    output::T
end

TraceSpec(p::NamedTuple, idxs::AbstractVector{<:Integer}, output) =
    TraceSpec(p, convert(Vector{Int}, idxs), output)

TraceSpec(::Tuple{}, args...) = TraceSpec(NamedTuple(), args...)

function map_traces(f, traces::AbstractArray{<:TraceSpec})
    ft = trace -> TraceSpec(trace.primary, trace.idxs, to_tuple(f(trace.output...)))
    map(ft, traces)
end

function to_plotspec(P::PlotFunc, g::TraceSpec, rank_dicts; kwargs...)
    plotspec = to_plotspec(P, convert_arguments(P, g.output...))
    names = propertynames(g.primary)
    d = Dict{Symbol, Node}()
    for (ind, key) in enumerate(names)
        f = function (user; palette = theme_scale)
            scale = is_scale(user) ? user : palette
            val = getproperty(g.primary, key)
            compute_attribute(scale, val, rank_dicts[ind])
        end
        d[key] = DelayedAttribute(f)
    end
    for (key, val) in node_pairs(kwargs)
        if !(key in names)
            d[key] = lift(t -> view(t, g.idxs), val)
        end
    end
    to_plotspec(P, plotspec; d...)
end

# convert a normalized style to a vector of TraceSpec
function to_traces(style::Style)
    g_args = to_args(style)
    g, args = g_args[1], g_args[2:end]
    len = column_length(args[1])
    pcols = map(x -> isa(x, AbstractVector) ? x : fill(x, len), g.columns)
    sa = isempty(pcols) ? fill(NamedTuple(), len) : StructArray(pcols)
    traces_from_groups(finduniquesorted(sa), args)
end

function traces_from_groups(keys, data)
    traces = TraceSpec[]
    for (key, idxs) in keys
        if any(x -> isa(x, ByColumn), key)
            m = maximum(width, data)
            for i in 1:m
                output = map(x -> extract_view(x, idxs, i), data)
                new_key = map(x -> x isa ByColumn ? i : x, key)
                push!(traces, TraceSpec(new_key, idxs, output))
            end
        else
            output =  map(x -> extract_view(x, idxs), data)
            push!(traces, TraceSpec(key, idxs, output))
        end
    end
    return traces
end

function convert_arguments(P::PlotFunc, st::Style; colorrange = automatic, kwargs...)
    style = normalize(st)
    pre_f = to_function(style)
    pre_traces = to_traces(style)
    f = adjust_globally(pre_f, pre_traces)
    traces = map_traces(f, pre_traces)

    rank_dicts = map(rank_dict, Tables.columntable([trace.primary for trace in traces]))
    series = (to_plotspec(P, trace, rank_dicts; to_kwargs(style)...) for trace in traces)
    pl = PlotList(series...)

    col = get(to_kwargs(style), :color, nothing)
    if colorrange === automatic && col isa AbstractVector{<:Real}
        colorrange = extrema_nan(col)
    end

    PlotSpec{MultiplePlot}(pl, colorrange = colorrange)
end

struct DelayedAttribute
    f::Function
end

combine(theme_val, d::DelayedAttribute; palette = nothing, kwargs...) = d.f(theme_val; palette = palette)
