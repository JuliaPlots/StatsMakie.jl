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

_maybe_val(::Val{T}) where {T} = T
_maybe_val(v) = v

# bin `x`s according to Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function _dotdensitybin(x, binwidth, bindir = Val(:lefttoright))
    if _maybe_val(bindir) === :righttoleft
        order = Base.Order.ReverseOrdering()
        binend_offset = -binwidth
        fcmp = ≤
    else
        order = Base.Order.ForwardOrdering()
        binend_offset = binwidth
        fcmp = ≥
    end

    n = length(x)
    idxs = sortperm(x; order = order)
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

_stack_offset(ndots, ::Val{:center}) = -ndots / 2
_stack_offset(ndots, ::Val{:centerwhole}) = -ceil(ndots / 2) + 1 / 2
_stack_offset(ndots, ::Union{Val{:up},Val{:right}}) = zero(ndots)
_stack_offset(ndots, ::Union{Val{:down},Val{:left}}) = -ndots

_stack_center(::Any) = -0.5
_stack_center(::Union{Val{:up},Val{:right}}) = 0
_stack_center(::Union{Val{:down},Val{:left}}) = -1

_flip_xy(::Nothing) = nothing
_flip_xy(t::NTuple{2}) = reverse(t)
_flip_xy(r::Rect{N,T}) where {N,T} = _flip_xy(Rect{2,T}(r))
_flip_xy(v::AbstractVector) = reverse(v[1:2])

# because dot sizes depend on limits, prevent limits from counting stack heights
function data_limits(P::DotPlot{<:Tuple{X, Y}}) where {X, Y}
    @extract P (orientation, stackdir, width)
    bb = xyz_boundingbox(to_value(P[1]), to_value(P[2]))
    w = widths(bb)
    T = eltype(bb)
    wv = T(to_value(width))
    w = Vec3{T}(w[1] + wv, w[2], w[3])
    o = bb.origin
    o = Vec3{T}(o[1] + T(_stack_center(Val(to_value(stackdir))) * wv), o[2], o[3])
    bb = FRect3D(o, w)
    if to_value(orientation) === :horizontal
        bb = FRect3D(_flip_xy(bb))
    end
    return bb
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
        bindir = Val(bindir)
        stackdir = Val(stackdir)
        padding = padding[1:2]
        xywidthpx = widths(area)
        new_limits = data_limits(plot)

        if orientation == :horizontal
            padding, xywidthpx, old_limits, new_limits = _flip_xy.((padding, xywidthpx, old_limits, new_limits))
        elseif orientation != :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end

        xylimits = if old_limits === nothing
            new_limits
        else
            union(old_limits, new_limits)
        end
        xywidth = widths(xylimits)[1:2]

        if binwidth === automatic
            data_width = widths(new_limits)[2] - width
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
        dotwidth = stackratio * markersize

        # correct for horizontal overlap due to stroke
        if strokewidth > 0
            markersize -= strokewidth
        end

        base_points = Point2f0[]
        offset_points = Point2f0[]
        for (xpos, centers_counts) in pos_centers_counts
            for (c, n) in centers_counts
                stack_offset = _stack_offset(n, stackdir)
                point = Point2f0(xpos, c)
                offsets = Point2f0.(dotwidth .* ((1:n) .- 1 / 2 .+ stack_offset) .- markersize/2, -markersize/2)
                append!(base_points, fill(point, n))
                append!(offset_points, offsets)
            end
        end

        if orientation == :horizontal
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
