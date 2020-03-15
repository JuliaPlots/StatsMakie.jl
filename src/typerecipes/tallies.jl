import Base: convert
import StatsBase: fit

export tally

# Utility type for storing tally results
struct Tallies{P<:AbstractVector,W<:AbstractVector,C<:AbstractVector{<:Integer}}
    positions::P
    widths::W
    counts::C

    function Tallies{P,W,C}(positions::P, widths::W, counts::C) where {P,W,C}
        all(≥(0), counts) || error("All counts in Tallies must be non-negative.")
        return new{P,W,C}(positions, widths, counts)
    end
end

function Tallies(positions, widths, counts)
    return Tallies{typeof.((positions, widths, counts))...}(positions, widths, counts)
end

function Base.convert(::Type{<:Tallies}, h::StatsBase.Histogram{<:Any,1})
    h.isdensity && error("Density histogram cannot be converted to Tallies.")
    edges = h.edges[1]
    counts = convert(AbstractVector{Int}, h.weights)
    widths = diff(edges)
    centers = StatsBase.midpoints(edges)
    ids = filter(i -> counts[i] > 0, eachindex(counts))
    return Tallies(centers[ids], widths[ids], counts[ids])
end

_unpoint(x) = (x,)
function _unpoint(points::AbstractVector{Point{N,T}}) where {N,T}
    n = length(points)
    xyz = ntuple(i -> Vector{T}(undef, n), N)
    @inbounds for i in 1:n, j in 1:N
        xyz[j][i] = points[i][j]
    end
    return xyz
end

convert_arguments(P::Type{<:AbstractPlot}, t::Tallies) = convert_arguments(P, 0, t)
convert_arguments(P::Type{<:AbstractPlot}, x::Number, t::Tallies) =
    convert_arguments(P, fill(float(x), length(t.positions)), t)
function convert_arguments(P::Type{<:AbstractPlot}, x, t::Tallies)
    ptype = plottype(P, Stacks) # set default to Stacks
    positions, widths, counts = t.positions, t.widths, t.counts

    args = (_unpoint(positions)..., x, counts)
    if ptype <: BarPlot
        kwargs = (; width = widths, fillto = x)
    elseif ptype <: Stacks
        kwargs = (; markersize = widths)
    else
        kwargs = NamedTuple()
    end

    return to_plotspec(ptype, convert_arguments(ptype, args...); kwargs...)
end

_tally(args...; kwargs...) = StatsBase.fit(Tallies, args...; kwargs...)

const tally = Analysis(_tally)

@inline _convert_order(::Any) = Base.Order.ForwardOrdering()
@inline _convert_order(::Val{:righttoleft}) = Base.Order.ReverseOrdering()

# smooth counts between adjacent bins using algorithm in
# Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function _smoothbins!(binids, x, cutoff)
    n = length(x)
    l₋ = l₊ = r₊ = 1
    @inbounds r₋ = findnext(!isequal(binids[l₋]), binids, l₋)
    r₋ === nothing && return binids
    @inbounds while r₋ < n
        l₊ = r₋ - 1
        r₊ = findnext(!isequal(binids[r₋]), binids, r₋)
        r₊ = r₊ === nothing ? n : r₊ - 1
        if abs(x[r₋] - x[l₊]) < cutoff
            r₋′ = r₋ + div((r₊ - r₋) - (l₊ - l₋), 2)
            while r₋′ < r₋
                binids[r₋′] = binids[r₊]
                r₋ -= 1
            end
            while r₋′ > r₋
                binids[r₋′] = binids[l₋]
                r₋ += 1
            end
        end
        l₋ = r₋
        r₋ = r₊ + 1
    end
    return binids
end

function _width(x)
    minx, maxx = extrema(x)
    return maxx - minx
end

StatsBase.fit(::Type{Tallies}, v::AbstractVector...; method = :dotdensity, kwargs...) =
    StatsBase.fit(Tallies, v..., _maybe_val(method); kwargs...)
function StatsBase.fit(::Type{Tallies}, v::AbstractVector, ::Val{:histodot}; kwargs...)
    h = StatsBase.fit(StatsBase.Histogram, v; kwargs...)
    t = convert(Tallies, h)
    return t
end

# bin `x`s according to Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function StatsBase.fit(
    ::Type{<:Tallies},
    x,
    ::Val{:dotdensity},
    bindir = Val(:lefttoright);
    nbins = 30,
    binwidth = _width(x) / nbins,
    smooth = false,
    kwargs...,
)
    idxs = sortperm(x; order = _convert_order(_maybe_val(bindir)))
    bindir = _maybe_unval(bindir)
    if bindir === :righttoleft
        binend_offset = -binwidth
        fcmp = ≤
    else
        binend_offset = binwidth
        fcmp = ≥
    end

    n = length(x)
    x = view(x, idxs)
    binids = view(Vector{Int}(undef, n), idxs)
    binid = 1
    @inbounds begin
        binids[1] = 1
        binend = x[1] + binend_offset
        for i in 2:n
            if fcmp(x[i], binend)
                binid += 1
                binend = x[i] + binend_offset
            end
            binids[i] = binid
        end
    end

    centers = Vector{float(eltype(x))}(undef, binid)
    @inbounds for (binid, idxs) in finduniquesorted(binids)
        xmin, xmax = x[first(idxs)], x[last(idxs)]
        centers[binid] = (xmin + xmax) / 2
    end

    # smooth the binids but keep the centers
    if smooth
        if bindir === :righttoleft
            idxs_rev = n:-1:1
            @inbounds smooth_x = view(x, idxs_rev)
            @inbounds smooth_binids = view(binids, idxs_rev)
        else
            smooth_x = x
            smooth_binids = binids
        end
        _smoothbins!(smooth_binids, smooth_x, binwidth / 4)
    end

    counts = [length(last(p)) for p in finduniquesorted(binids)]
    widths = fill(binwidth, length(counts))
    return Tallies(centers, widths, counts)
end

# for each in sorted `x`, get range of indices of all `x` within radius `binwidth`
function _adjacent_ranges(x, binwidth)
    n = length(x)
    lowers = Vector{Int}(undef, n)
    uppers = Vector{Int}(undef, n)
    i₊ = 1
    @inbounds for i₋ in Base.OneTo(n)
        x₋ = x[i₋]
        while i₊ ≤ n && x[i₊] < x₋ + binwidth / 2
            lowers[i₊] = i₋
            i₊ += 1
        end
        # TODO: probably could be made more efficient with a backwards pass
        uppers[i₋:i₊-1] .= i₊ - 1
    end
    return map(UnitRange, lowers, uppers)
end

# setdiff assuming interval `y` is not a proper subset of interval `x`
# so output is also UnitRange
function _rangediff(x::UnitRange, y::UnitRange)
    a, b, c, d = first(x), last(x), first(y), last(y)
    a < c && return UnitRange(a, min(b + 1, c) - 1)
    b > d && return UnitRange(max(a - 1, d) + 1, b)
    return UnitRange(a, a - 1) # empty range
end

# bin univariate `x`s according to Dang, 2010. doi: 10.1109/TVCG.2010.197
function StatsBase.fit(
    ::Type{<:Tallies},
    x::AbstractVector{<:Number},
    ::Val{:dotdensity},
    ::Val{:undirected};
    nbins = 30,
    binwidth = _width(x) / nbins,
    kwargs...,
)
    idxs = sortperm(x)
    x = view(x, idxs)
    adj_ranges = _adjacent_ranges(x, binwidth)
    binids = view(Vector{Int}(undef, length(x)), idxs)
    centers = float(eltype(x))[]
    counts = Int[]
    binid = 1
    @inbounds while !isempty(adj_ranges)
        i = sortperm(adj_ranges; rev = true, by = length)[1]
        r = copy(adj_ranges[i])
        rmin, rmax = extrema(r)
        center = (x[rmin] + x[rmax]) / 2
        binids[r] .= binid
        push!(centers, center)
        push!(counts, rmax - rmin + 1)
        adj_ranges = _rangediff.(adj_ranges, Ref(r))
        filter!(!isempty, adj_ranges)
        binid += 1
    end
    widths = fill(binwidth, length(counts))
    return Tallies(centers, widths, counts)
end

function adj_sets(x, y)
    x = Point2.(x, y)
end

# bin bivariate `x`s according to Dang, 2010. doi: 10.1109/TVCG.2010.197
function StatsBase.fit(
    T::Type{<:Tallies},
    x::AbstractVector{<:Number},
    y::AbstractVector{<:Number},
    method::Val{:dotdensity};
    kwargs...,
)
    return StatsBase.fit(T, Point2.(x, y), method; kwargs...)
end
# TODO: implement more efficiently
function StatsBase.fit(
    ::Type{<:Tallies},
    x::AbstractVector{<:Point{2}},
    ::Val{:dotdensity};
    nbins = 100,
    binwidth = sqrt(prod(_width(x)) / nbins), # ~nbins in ellipse defined by data
    kwargs...,
)
    nx = length(x)
    adj_inds = map(Set, eachindex(x))
    binrad = binwidth / 2
    @inbounds for i in 2:nx, j in 1:i-1
        d = StatsBase.norm(x[i] - x[j])
        if d < binrad
            push!(adj_inds[i], j)
            push!(adj_inds[j], i)
        end
    end

    binids = Vector{Int}(undef, nx)
    centers = eltype(x)[]
    counts = Int[]
    binid = 1
    @inbounds while !isempty(adj_inds)
        i = sortperm(adj_inds; rev = true, by = length)[1]
        r = adj_inds[i]
        adj_points = getindex.(Ref(x), r)
        center = sum(extrema(adj_points)) / 2
        for ri in r
            binids[ri] = binid
        end
        push!(centers, center)
        push!(counts, length(r))
        adj_inds = setdiff.(adj_inds, Ref(r))
        filter!(!isempty, adj_inds)
        binid += 1
    end
    widths = fill(binwidth, length(counts))
    return Tallies(centers, widths, counts)
end
