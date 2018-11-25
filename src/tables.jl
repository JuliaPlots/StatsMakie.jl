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
Base.merge(f::Function, s::Style) = merge(Group(f), s)
Base.merge(s::Style, f::Function) = merge(s, Group(f))

extract_column(t, col::AbstractVector) = columns(t, col)
extract_column(t, col) = columns(t, col)
extract_column(t, col::AbstractArray) =
    mapslices(v -> extract_column(t, v[1]), col, dims = 1)

extract_column(t, grp::Group) = Group(extract_columns(t, columns(grp)), grp.f)

extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

function extract_columns(df, st::Style)
    t = table(df)
    Style(
        extract_columns(t, st.args)...;
        extract_columns(t, st.kwargs)...
    )
end

to_args(st::Style) = st.args

to_kwargs(st::Style) = st.kwargs

used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, f, args...)))

used_attributes(P::PlotFunc, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, args...)))

function convert_arguments(P::PlotFunc, f::Function, arg::GoG, args...; kwargs...)
    style = foldl(merge, (to_style(el) for el in args), init = to_style(arg))
    convert_arguments(P, merge(f, style); kwargs...)
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

function to_plotspec(P::PlotFunc, g::TraceSpec, uniquevalues; kwargs...)
    plotspec = to_plotspec(P, convert_arguments(P, g.output...))
    names = propertynames(g.primary)
    d = Dict{Symbol, Node}()
    for (ind, key) in enumerate(names)
        f = function (scale = nothing)
            def = get(default_scales, key, nothing)
            s = something(to_scale(scale), def)
            val = getproperty(g.primary, key)
            uniquevalues[ind](s, val)
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

function convert_arguments(P::PlotFunc, st::Style; colorrange = automatic, kwargs...)
    style = normalize(st)
    g_args = to_args(style)
    g, args = g_args[1], g_args[2:end]
    N = length(args)
    f = g.f
    names = colnames(g)
    cols = columns(g)
    vec_args = map(object2vec, args)
    len = length(g)
    len == 0 && (len = length(vec_args[1]))
    coltable = table(1:len, cols..., vec_args...;
        names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)

    t = groupby(coltable, names, usekey = true) do key, dd
        idxs = column(dd, :row)
        out = to_tuple(f(map(vec2object, columns(dd, Not(:row)))...; kwargs...))
        tup = (rows = idxs, output = out)
    end
    if (t isa NamedTuple)
        t = table((row = [1], rows = [t.rows], output = [t.output]))
        primary = fill(NamedTuple(), 1)
    else
        primary = rows(t, Keys())
    end
    idxs, output = columns(t, (:rows, :output))
    traces = (TraceSpec(p, i, o) for (p, i, o) in zip(primary, idxs, output))
    uniquevalues = map(UniqueValues, cols)
    series = (to_plotspec(P, trace, uniquevalues; to_kwargs(style)...) for trace in traces)
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

combine(val, d::DelayedAttribute) = d.f(val)
combine(d::DelayedAttribute) = d.f()
