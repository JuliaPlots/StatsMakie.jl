struct UniqueValues{S, T1<:AbstractArray{S}, T2<:AbstractArray{S}}
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
    f::Function
end

Group(c::NamedTuple) = Group(c, tuple)

Group(v, f::Function = tuple) = Group((color = v,), f)
Group(f::Function = tuple; kwargs...) = Group(values(kwargs), f)

IndexedTables.columns(grp::Group) = grp.columns
IndexedTables.colnames(grp::Group) = propertynames(columns(grp))

struct Colwise end
const colwise = Colwise()

combine_gog(f1, f2) = (args...) -> f1(to_tuple(f2(args...))...)
combine_gog(f1, f2::typeof(tuple)) = f1
combine_gog(f1::typeof(tuple), f2) = f2
combine_gog(f1::typeof(tuple), f2::typeof(tuple)) = tuple

Base.merge(g1::Group, g2::Group) = Group(merge(g1.columns, g2.columns), combine_gog(g1.f, g2.f))
Base.merge(f::Function, g::Group) = merge(Group(f), g)
Base.merge(g::Group, f::Function) = merge(g, Group(f))

Base.:*(g1::Group, g2::Group) = merge(g1, g2)

function Base.length(grp::Group)
    cols = grp.columns
    isempty(cols) ? 0 : length(cols[1])
end

to_pair(P, t) = P => t
to_pair(P, p::Pair) = to_pair(plottype(P, first(p)), last(p))


struct ViewVector{T, A <: AbstractArray{T}} <: AbstractVector{T}
    w::A
    ViewVector(w::AbstractArray{T, M}) where {T, M} = new{T, typeof(w)}(w)
end

Base.size(v::ViewVector) = size(v.w)[1:1]
Base.getindex(v::ViewVector, i) = Base.getindex(v.w, i, axes(v.w)[2:end]...)

Base.view(v::ViewVector, i) = ViewVector(Base.view(v.w, i, axes(v.w)[2:end]...))


vec2object(x::Columns) = Tuple(columns(x))
vec2object(x) = x
vec2object(v::ViewVector) = v.w

object2vec(v::Union{Tuple, NamedTuple}) = Columns(v)
object2vec(v::AbstractVector) = v
object2vec(v::AbstractArray) = ViewVector(v)
