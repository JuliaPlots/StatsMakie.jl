using AbstractPlotting: parent_scene, xyz_boundingbox

@recipe(DotPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        alpha = 1,
        strokecolor = :black,
        strokewidth = 0,
        orientation = :horizontal,
        width = 1.0, # used for padding only
        stackdir = :up,
        stackratio = 1,
        dotscale = 1,
        binwidth = automatic,
        maxbins = 30,
        method = automatic,
        bindir = :lefttoright,
        origin = automatic,
        closed = :left,
    )
    t
end

conversion_trait(x::Type{<:DotPlot}) = SampleBased()

Base.@propagate_inbounds _outermean(x, l, u) = (x[l] + x[u]) / 2

function _countbins(binids)
    nonzero_counts = Dict(map(finduniquesorted(binids)) do p
        binid, tmp = p
        return binid => length(tmp)
    end)
    maxbinid = maximum(keys(nonzero_counts))
    return [get(nonzero_counts, i, 0) for i in 1:maxbinid]
end

@inline _maybe_val(v::Val) = v
@inline _maybe_val(v) = Val(v)

@inline _maybe_unval(::Val{T}) where {T} = T
@inline _maybe_unval(v) = v

@inline _convert_order(::Any) = Base.Order.ForwardOrdering()
@inline _convert_order(::Val{:righttoleft}) = Base.Order.ReverseOrdering()

# bin `x`s according to Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function _bindots(
    ::Val{:dotdensity},
    x,
    binwidth,
    bindir = Val(:lefttoright);
    idxs = sortperm(x; order = _convert_order(_maybe_val(bindir))),
)
    if _maybe_unval(bindir) === :righttoleft
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
    for (binid, idxs) in finduniquesorted(binids, 1:n)
        n = length(idxs)
        @inbounds centers[binid] = (x[idxs[1]] + x[idxs[n]]) / 2
    end

    return parent(binids), centers, idxs
end

# bin `x`s using a histogram
# we don't use StatsBase here since we want bin ids
function _bindots(
    ::Val{:histodot},
    x,
    binwidth;
    idxs = sortperm(x),
    origin = automatic,
    closed = :left,
)
    if _maybe_unval(closed) === :left
        fcmp = (a, b, c) -> (b < c || a == b)
    else
        fcmp = (a, b, c) -> b ≤ c
    end

    n = length(x)
    x = view(x, idxs)
    @inbounds xmin, xmax = x[1], x[n]
    if origin === automatic
        xrange = xmax - xmin
        nbins = Int(ceil(xrange / binwidth))
        histrange = nbins * binwidth
        origin = xmin - (histrange - xrange) / 2
    else
        nbins = Int(ceil((xmax - origin) / binwidth))
    end


    binids = view(Vector{Int}(undef, n), idxs)
    centers = Vector{float(eltype(x))}(undef, nbins)
    i = 1
    @inbounds begin
        for binid in 1:nbins
            binend = origin + binid * binwidth
            centers[binid] = binend - binwidth / 2
            while i ≤ n && fcmp(binend - binwidth, x[i], binend)
                binids[i] = binid
                i += 1
            end
        end
    end

    return parent(binids), centers, idxs
end

function convert_arguments(P::Type{<:DotPlot}, h::StatsBase.Histogram{<:Any,1})
    h.isdensity &&
    throw(ErrorException("Histogram must not be density histogram for dotplot."))
    edges = h.edges[1]
    nbins = length(edges)
    widths = diff(edges)
    binwidth = widths[1]
    if any(w -> !isapprox(w, binwidth), widths)
        throw(ErrorException("Histogram must have bins of equal width for dotplot."))
    end
    centers = StatsBase.midpoints(edges)
    counts = h.weights
    # make a new dataset that has the same bins
    y = [c for (c, n) in zip(centers, counts) for _ in 1:n]
    return to_plotspec(P, convert_arguments(P, y); binwidth = binwidth)
end

# offset from base point in stack direction in units of markersize
# ratio is distance between centers of adjacent dots
function _stack_offsets(pos, ratio, ::Union{Val{:up},Val{:right}})
    return @. ratio * (pos - 1) + 1 / 2
end
function _stack_offsets(pos, ratio, ::Union{Val{:down},Val{:left}})
    return @. -ratio * (pos - 1) - 1 / 2
end
function _stack_offsets(pos, ratio, ::Val{:center})
    n = length(pos)
    return @. ratio * (pos - (n + 1) / 2)
end
function _stack_offsets(pos, ratio, ::Val{:centerwhole})
    n = length(pos)
    return @. ratio * (pos - floor((n + 1) / 2)) + 1 / 2
end

@inline _stack_center(::Any) = -0.5
@inline _stack_center(::Union{Val{:up},Val{:right}}) = 0
@inline _stack_center(::Union{Val{:down},Val{:left}}) = -1

_flip_xy(::Nothing) = nothing
_flip_xy(t::NTuple{2}) = reverse(t)
_flip_xy(r::Rect{N,T}) where {N,T} = _flip_xy(Rect{2,T}(r))
_flip_xy(v::AbstractVector) = reverse(v[1:2])

function _dot_limits(x, y, width, stackdir)
    bb = xyz_boundingbox(x, y)
    T = eltype(bb)
    wv = T(width)
    xoffset = T(_stack_center(_maybe_val(stackdir)) * wv)
    origin, widths = bb.origin, bb.widths
    @inbounds widths = Vec2{T}(widths[1] + wv, widths[2])
    @inbounds origin = Vec2{T}(origin[1] + xoffset, origin[2])
    return FRect2D(origin, widths)
end

# because dot sizes depend on limits, prevent limits from counting stack heights
function data_limits(P::DotPlot{<:Tuple{X,Y}}) where {X,Y}
    @extract P (orientation, width, stackdir)
    bb = _dot_limits(to_value.((P[1], P[2], width, stackdir))...)
    if to_value(orientation) === :horizontal
        bb = _flip_xy(bb)
    end
    return FRect3D(bb)
end

function AbstractPlotting.plot!(plot::DotPlot)
    @extract plot (
        color,
        alpha,
        strokecolor,
        strokewidth,
        orientation,
        width,
        stackdir,
        stackratio,
        dotscale,
        binwidth,
        maxbins,
        method,
        bindir,
        origin,
        closed,
    )

    scene = parent_scene(plot)

    outputs = lift(
        plot[1],
        plot[2],
        scene.data_limits,
        pixelarea(plot),
        scene.padding,
        orientation,
        width,
        stackdir,
        stackratio,
        dotscale,
        strokewidth,
        binwidth,
        maxbins,
        method,
        bindir,
        origin,
        closed,
    ) do x,
    y,
    old_limits,
    area,
    padding,
    orientation,
    width,
    stackdir,
    stackratio,
    dotscale,
    strokewidth,
    binwidth,
    maxbins,
    method,
    bindir,
    origin,
    closed
        npoints = length(y)

        method = method === automatic ? Val(:dotdensity) : _maybe_val(method)
        binargs, binkwargs = if method === Val(:dotdensity)
            (_maybe_val(bindir),), NamedTuple()
        else
            (), (; origin = _maybe_unval(origin), closed = _maybe_unval(closed))
        end
        stackdir = _maybe_val(stackdir)
        orientation = _maybe_unval(orientation)

        xywidthpx = widths(area)
        padding = padding[1:2]
        if orientation === :horizontal
            padding, xywidthpx, old_limits = _flip_xy.((padding, xywidthpx, old_limits))
        elseif orientation != :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end
        ywidthpx = xywidthpx[2]
        new_limits = _dot_limits(x, y, width, stackdir)
        xylimits = if old_limits === nothing
            new_limits
        else
            union(FRect2D(old_limits), new_limits)
        end
        ywidth = widths(xylimits)[2]

        if binwidth === automatic
            binwidth = ywidth / maxbins
        end

        ywidthtot = ywidth * (1 + 2 * padding[2])
        pxperyunit = ywidthpx ./ ywidthtot
        markersize = dotscale * binwidth * pxperyunit

        # correct for horizontal overlap due to stroke
        if strokewidth > 0
            markersize -= strokewidth
        end

        basex = float(eltype(x))[]
        basey = float(eltype(y))[]
        counts = Int[]
        binids = Int[]
        sortidxs = Vector{Int}(undef, npoints)
        j = 1
        for (groupid, xidxs) in finduniquesorted(x)
            v = view(y, xidxs)
            group_binids, group_centers, vidxs =
                _bindots(method, v, binwidth, binargs...; pairs(binkwargs)...)
            group_counts = _countbins(group_binids)
            n = length(group_centers)
            append!(basex, fill(groupid, n))
            append!(basey, group_centers)
            append!(counts, group_counts)
            append!(binids, group_binids)
            m = length(v)
            sortidxs[j:j+m-1] .= view(xidxs, vidxs)
            j += m
        end

        base_points = view(Vector{Point2f0}(undef, npoints), sortidxs)
        offset_points = view(Vector{Point2f0}(undef, npoints), sortidxs)
        j = 1
        @inbounds for i in eachindex(basex, basey, counts)
            n = counts[i]
            stack_pos = 1:n
            stack_offsets = _stack_offsets(stack_pos, stackratio, stackdir)
            # default offset is (-markersize / 2, -markersize / 2)
            offsets = Point2f0.(markersize .* (stack_offsets .- 1 / 2), -markersize / 2)
            offset_points[j:j+n-1] .= offsets
            base_points[j:j+n-1] .= Ref(Point2f0(basex[i], basey[i]))
            j += n
        end
        base_points, offset_points = parent(base_points), parent(offset_points)

        if orientation === :horizontal
            base_points = _flip_xy.(base_points)
            offset_points = _flip_xy.(offset_points)
        end

        return base_points, offset_points, markersize * px
    end
    points = @lift($outputs[1])
    marker_offset = @lift($outputs[2])
    markersize = @lift($outputs[3])

    scatter!(
        plot,
        points;
        markersize = markersize,
        color = color,
        alpha = alpha,
        strokecolor = strokecolor,
        strokewidth = strokewidth,
        marker_offset = marker_offset,
    )
end
