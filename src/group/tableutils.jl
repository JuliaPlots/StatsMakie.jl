struct GroupIdxsIterator{T <: AbstractVector}
    vec::T
    perm::Vector{Int}
end

GroupIdxsIterator(vec::AbstractVector) = GroupIdxsIterator(vec, sortperm(vec))

function to_namedtuple(t)
    pn = propertynames(t)
    NamedTuple{pn}(Tuple(getproperty(t, n) for n in pn))
end

to_namedtuple(t::NamedTuple) = t

function Base.iterate(n::GroupIdxsIterator, i = 1)
    vec, perm = n.vec, n.perm
    l = length(perm)
    i > l && return nothing
    row = vec[perm[i]]
    i1 = i
    while i1 <= l && isequal(row, vec[perm[i1]])
        i1 += 1
    end
    return (to_namedtuple(row) => perm[i:(i1-1)], i1)
end
