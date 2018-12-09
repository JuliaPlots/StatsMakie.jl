struct UniqueValues{S, T1<:AbstractArray, T2<:AbstractArray{S}}
    values::T1
    unique::T2
    value2index::Dict{S, Int}
end

function UniqueValues(col, s = unique(sort(col)))
    value2index = Dict(zip(s, 1:length(s)))
    UniqueValues(col, s, value2index)
end

function (cs::UniqueValues)(s, el)
    scale = to_scale(s)
    @assert scale !== nothing
    @assert typeof(scale) !== typeof(s)
    cs(scale, el)
end

(cs::UniqueValues)(scale::Function, el) = scale(el)

function (cs::UniqueValues)(scale::AbstractArray, el)
    scale[(cs.value2index[el] - 1) % length(scale) + 1]
end

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

concatenate(v::Union{Tuple, NamedTuple}...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)
