struct Extract
    args::Tuple
    kwargs::NamedTuple
    Extract(args...; kwargs...) = new(args, values(kwargs))
end

extract_column(t, col) = column(t, col)

function extract_column(t, grp::Group)
    new_cols = extract_columns(t, columns(grp))
    Group(new_cols, grp.scales)
end

extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

function extract_columns(df, e::Extract)
    t = table(df)
    Extract(
        extract_columns(t, e.args)...;
        pairs(extract_columns(t, e.kwargs))...
    )
end

to_args(e::Extract) = e.args

to_kwargs(e::Extract) = e.kwargs

function plot!(p::Combined{T, <: Tuple{Any, Extract}}) where T
    t, e = to_value.(p[1:2])
    extracted = extract_columns(t, e)
    attr = copy(Theme(p))

    for (key, val) in pairs(to_kwargs(extracted))
        attr[key] = val
    end

    plot!(p, Combined{T}, attr, to_args(extracted)...)
end
