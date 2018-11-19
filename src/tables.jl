struct Style
    args::Tuple
    kwargs::NamedTuple
    Style(args...; kwargs...) = new(args, values(kwargs))
end

Base.merge(s1::Style, s2::Style) = Style(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)
Base.:*(s1::Style, s2::Style) = merge(s1, s2)

Base.merge(g::Group, s::Style) = merge(Style(g), s)
Base.merge(f::Function, s::Style) = merge(Group(f), s)
Base.merge(s::Style, g::Union{Group, Function}) = merge(g, s)

const GroupOrStyle = Union{Style, Group}

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

function convert_arguments(P::PlotFunc, f::Function, df, arg::GroupOrStyle, args::GroupOrStyle...; kwargs...)
    style = extract_columns(df, foldl(merge, args, init = arg))
    convert_arguments(P, merge(f, style); kwargs...)
end

function convert_arguments(P::PlotFunc, df, arg::GroupOrStyle, args::GroupOrStyle...; kwargs...)
    style = extract_columns(df, foldl(merge, args, init = arg))
    convert_arguments(P, style; kwargs...)
end

function convert_arguments(P::PlotFunc, g::Group, args...; kwargs...)
    convert_arguments(P, Style(g, args...); kwargs...)
end

function convert_arguments(P::PlotFunc, st::Style; kwargs...)
    _args = to_args(st)
    g_args = _args[1] isa Group ? _args : (Group(), _args...)
    g, args = g_args[1], g_args[2:end]
    N = length(args)
    f = g.f
    names = colnames(g)
    cols = columns(g)
    len = length(g)
    vec_args = map(object2vec, args)
    len == 0 && (len = length(vec_args[1]))
    funcs = map(UniqueValues, cols)
    coltable = table(1:len, cols..., vec_args...;
        names = [:row, names..., (Symbol("x$i") for i in 1:N)...], copy = false)

    t = groupby(coltable, names, usekey = true) do key, dd
        idxs = column(dd, :row)
        out = to_tuple(f(map(vec2object, columns(dd, Not(:row)))...; kwargs...))
        tup = (rows = idxs, output = out)
    end
    (t isa NamedTuple) && (t = table((rows = [t.rows], output = [t.output])))

    funcs = map(UniqueValues, cols)

    function adapt(theme, i)
        scales = map(key -> getscale(theme, key), names)
        attr = copy(theme)
        row = t[i]
        for (ind, key) in enumerate(names)
            val = getproperty(row, key)
            attr[key] = lift(funcs[ind], scales[ind], to_node(val))
        end
        for (key, val) in Iterators.flatten((attr, node_pairs(pairs(to_kwargs(st)))))
            if !(key in names)
                attr[key] = lift(t -> _split(t, len, row.rows), val, typ = _typ(val[]))
            end
        end
        attr
    end
    pl = PlotList(column(t, :output); transform_attributes = [theme -> adapt(theme, i) for i in 1:length(t)])
    convert_arguments(P, pl)
end
