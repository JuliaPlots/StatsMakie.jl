struct Style
    args::Tuple
    kwargs::NamedTuple
    Style(args...; kwargs...) = new(args, values(kwargs))
end

Base.merge(s1::Style, s2::Style) = Style(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)
Base.:*(s1::Style, s2::Style) = merge(s1, s2)

Base.merge(g::Group, s::Style) = merge(Style(g), s)
Base.merge(s::Style, g::Group) = merge(g, s)

const GroupStyle = Union{Style, Group}

extract_column(t, col) = column(t, col)

function extract_column(t, grp::Group)
    new_cols = extract_columns(t, columns(grp))
    Group(new_cols, grp.scales)
end

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

function plot!(p::Combined{T, <: Tuple{Any, GroupStyle, Vararg{GroupStyle, N}}}) where {T, N}
    t = to_value(p[1])
    styles = to_value.(p[2:(N+2)])
    st = foldl(merge, styles)
    extracted = extract_columns(t, st)
    attr = copy(Theme(p))

    for (key, val) in pairs(to_kwargs(extracted))
        attr[key] = val
    end

    plot!(p, Combined{T}, attr, to_args(extracted)...)
end
