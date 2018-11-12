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

const GroupStyle = Union{Style, Group}

extract_column(t, col) = column(t, col)

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

function convert_arguments(P::PlotFunc, f::Function, df, arg::GroupStyle, args::GroupStyle...; kwargs...)
    style = extract_columns(df, foldl(merge, args, init = arg))
    convert_arguments(P, merge(f, style); kwargs...)
end

function convert_arguments(P::PlotFunc, df, arg::GroupStyle, args::GroupStyle...; kwargs...)
    style = extract_columns(df, foldl(merge, args, init = arg))
    convert_arguments(P, style; kwargs...)
end

function convert_arguments(P::PlotFunc, st::Style; kwargs...)
    args = to_args(st)
    empty_grp = Group()
    g_args = args[1] isa Group ? args : (empty_grp, args...)
    converted_args = convert_arguments(P, g_args...; kwargs...)
    pt = last(converted_args)[1]
    for (key, val) in pairs(to_kwargs(st))
        pt.attr[key] = to_node(val)
    end
    to_pair(P, converted_args)
end
