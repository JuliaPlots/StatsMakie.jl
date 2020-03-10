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
        bindir = :lefttoright,
    )
    t
end

conversion_trait(x::Type{<:DotPlot}) = SampleBased()

Base.@propagate_inbounds _outermean(x, l, u) = (x[l] + x[u]) / 2

function _centers_counts(x, binids, idxs = sortperm(x); func = _outermean)
    centers = float(eltype(x))[]
    counts = Int[]
    for (binid, tmp) in finduniquesorted(binids, idxs)
        n = length(tmp)
        @inbounds push!(centers, func(x, tmp[1], tmp[n]))
        push!(counts, n)
    end
    return centers, counts
end

@inline _maybe_val(v::Val) = v
@inline _maybe_val(v) = Val(v)

@inline _maybe_unval(::Val{T}) where {T} = T
@inline _maybe_unval(v) = v

@inline _convert_order(::Any) = Base.Order.ForwardOrdering()
@inline _convert_order(::Val{:righttoleft}) = Base.Order.ReverseOrdering()

# bin `x`s according to Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function _dotdensitybin(
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

    return parent(binids), idxs
end

# offset from base point in stack direction in units of markersize
# ratio is distance between centers of adjacent dots
#
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
        bindir,
        strokewidth,
    )

    binfunc = _dotdensitybin
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
        binwidth,
        maxbins,
        bindir,
        strokewidth,
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
    binwidth,
    maxbins,
    bindir,
    strokewidth
        bindir = _maybe_val(bindir)
        stackdir = _maybe_val(stackdir)
        orientation = _maybe_unval(orientation)
        padding = padding[1:2]
        xywidthpx = widths(area)

        if orientation === :horizontal
            padding, xywidthpx, old_limits = _flip_xy.((padding, xywidthpx, old_limits))
        elseif orientation != :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end

        new_limits = _dot_limits(x, y, width, stackdir)
        xylimits = if old_limits === nothing
            new_limits
        else
            union(old_limits, new_limits)
        end
        xywidth = widths(xylimits)[1:2]

        if binwidth === automatic
            data_width = widths(new_limits)[2]
            binwidth = data_width / maxbins
        end

        pos_centers_counts = map(finduniquesorted(x)) do p
            key, xidxs = p
            v = view(y, xidxs)
            binids, vidxs = binfunc(v, binwidth, bindir)
            centers, counts = _centers_counts(v, binids, vidxs)
            return key => zip(centers, counts)
        end

        xywidthtot = xywidth .* (1 .+ 2 .* padding)
        pxperunit = xywidthpx ./ xywidthtot
        markersize = dotscale * binwidth * pxperunit[2]

        # correct for horizontal overlap due to stroke
        if strokewidth > 0
            markersize -= strokewidth
        end

        base_points = Point2f0[]
        offset_points = Point2f0[]
        for (xpos, centers_counts) in pos_centers_counts
            for (base, n) in centers_counts
                stack_pos = 1:n
                stack_offsets = _stack_offsets(stack_pos, stackratio, stackdir)
                # default offset is (-markersize / 2, -markersize / 2)
                offsets = Point2f0.(markersize .* (stack_offsets .- 1 / 2), -markersize / 2)
                append!(offset_points, offsets)
                append!(base_points, fill(Point2f0(xpos, base), n))
            end
        end

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
