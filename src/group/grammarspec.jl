# utils

concatenate(v::Union{Tuple, NamedTuple}...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)

ncols(v::Tuple) = length(v)
ncols(v::AbstractVector) = 1
ncols(v::AbstractArray) = mapreduce(length, *, tail(axes(v)))

column_length(v::Union{Tuple, NamedTuple}) = column_length(v[1])
column_length(v::AbstractVector) = length(v)
column_length(v::AbstractArray) = length(axes(v, 1))

extract_view(v::Union{Tuple, NamedTuple}, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)
function extract_view(v::AbstractArray{<:Any, N}, idxs) where {T, N}
    args = ntuple(i -> i == 1 ? idxs : Colon(), N)
    view(v, args...)
end

extract_view(v::Union{Tuple, NamedTuple}, idxs, n) = extract_view(v[n], idxs)
extract_view(v::AbstractVector, idxs, n) = view(v, idxs)
function extract_view(v::AbstractArray, idxs, n)
    ax = tail(axes(v))
    c = CartesianIndices(ax)[n]
    view(v, idxs, Tuple(c)...)
end

extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)
extract_column(t, col::AbstractArray) =
    mapslices(v -> extract_column(t, v[1]), col, dims = 1)

extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

# --------

struct Analysis{T, N<:NamedTuple}
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end
Analysis() = Analysis(tuple)

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
(an::Analysis)(args...; kwargs...) = an.f(args...; kwargs..., an.kwargs...)

Base.merge(a1::Analysis, a2::Analysis) = a2

struct Group
    columns::NamedTuple
    Group(; kwargs...) = new(values(kwargs))
end

Group(v) = Group(color = v)

Base.merge(g1::Group, g2::Group) = Group(; merge(g1.columns, g2.columns)...)

struct Data{T}
    table::T
end
Data() = Data(nothing)

Base.merge(d1::Data, d2::Data) = d2

struct Style
    args::Tuple
    kwargs::NamedTuple
    Style(args...; kwargs...) = new(args, values(kwargs))
end

Base.merge(s1::Style, s2::Style) = Style(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)

struct GrammarSpec
    analysis::Analysis
    data::Data
    group::Group
    style::Style
end

const GoG = Union{Analysis, Data, Group, Style}

promote_gog(f::Function) = Analysis(f)
promote_gog(g::GoG) = g
promote_gog(x) = Style(x)

function Base.merge(g::GrammarSpec, val::T) where {T<:GoG}
    vals = ntuple(4) do i
        def = getfield(g, i)
        T <: fieldtype(GrammarSpec, i) ? merge(def, val) : def
    end
    GrammarSpec(vals...)
end

function GrammarSpec(list)
    init = GrammarSpec(Analysis(), Data(), Group(), Style())
    mapfoldl(promote_gog, merge, list; init = init)
end

Base.:*(g1::GoG, g2::GoG) = foldl(*, (g1, g2), init = GrammarSpec(()))

struct TraceSpec{N<:NamedTuple, T<:Tuple}
    primary::N
    idxs::Vector{Int}
    output::T
end

TraceSpec(p::NamedTuple, idxs::AbstractVector{<:Integer}, output::Tuple) =
    TraceSpec(p, convert(Vector{Int}, idxs), output)

TraceSpec(::Tuple{}, args...) = TraceSpec(NamedTuple(), args...)

function groupstyle(gs::GrammarSpec)
    t = gs.data.table
    t === nothing && return gs.group, gs.style
    grp = Group(; extract_columns(t, gs.group.columns)...)
    style = Style(
                  extract_columns(t, gs.style.args)...;
                  extract_columns(t, gs.style.kwargs)...
                 )
    return grp, style
end

struct ByColumn end
const bycolumn = ByColumn()

Base.isless(::ByColumn, ::ByColumn) = false
extract_column(t, c::ByColumn) = c

# convert a Group and a Style to a vector of TraceSpec
function traces_rankdicts_attributes(gs::GrammarSpec)
    g, style = groupstyle(gs)
    data = style.args
    len = column_length(data)
    pcols = map(t -> t isa ByColumn ? fill(t, len) : t, g.columns)
    sa = isempty(pcols) ? fill(NamedTuple(), len) : StructArray(pcols)
    keys = finduniquesorted(sa)

    traces = TraceSpec[]
    for (key, idxs) in keys
        if any(x -> isa(x, ByColumn), key)
            m = maximum(ncols, data)
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

    analysis = adjust_globally(gs.analysis, traces)
    comp_traces = map_traces(analysis, traces)
    table = Tables.columntable([trace.primary for trace in comp_traces])
    rankdicts = map(rankdict, table)
    return comp_traces, rankdicts, style.kwargs
end

function map_traces(f, traces::AbstractArray{<:TraceSpec})
    map(traces) do trace
        TraceSpec(trace.primary, trace.idxs, to_tuple(f(trace.output...)))
    end
end

