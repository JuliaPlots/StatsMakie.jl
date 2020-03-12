using AbstractPlotting: parent_scene, xyz_boundingbox

@recipe(DotPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        alpha = 1,
        strokecolor = :black,
        strokewidth = 0,
        orientation = :vertical,
        width = 0.8, # used for padding only
        stackdir = :center,
        stackratio = 1,
        dotscale = 1,
        binwidth = automatic,
        maxbins = 30,
        method = :dotdensity,
        # dotdensity options
        bindir = :lefttoright,
        smooth = false,
        # histodot options
        origin = automatic,
        closed = :left,
    )
    t
end

conversion_trait(x::Type{<:DotPlot}) = SampleBased()

function _countbins(binids)
    nonzero_counts = Dict(map(finduniquesorted(binids)) do p
        binid, idxs = p
        return binid => length(idxs)
    end)
    maxbinid = maximum(keys(nonzero_counts))
    counts = map(i -> get(nonzero_counts, i, 0), Base.OneTo(maxbinid))
    return counts
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
    return UnitRange(a, a - 1)
end

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

# bin `x`s according to Wilkinson, 1999. doi: 10.1080/00031305.1999.10474474
function _bindots(
    ::Val{:dotdensity},
    x,
    binwidth,
    bindir = Val(:lefttoright),
    args...;
    idxs = sortperm(x; order = _convert_order(_maybe_val(bindir))),
    smooth = false,
    kwargs...,
)
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

    return parent(binids), centers, idxs
end

# bin `x`s according to Dang, 2010. doi: 10.1109/TVCG.2010.197
function _bindots(
    ::Val{:dotdensity},
    x,
    binwidth,
    ::Val{:undirected},
    args...;
    idxs = sortperm(x),
    kwargs...,
)
    x = view(x, idxs)
    adj_ranges = _adjacent_ranges(x, binwidth)
    binids = view(Vector{Int}(undef, length(x)), idxs)
    centers = float(eltype(x))[]
    binid = 1
    @inbounds while !isempty(adj_ranges)
        i = sortperm(adj_ranges; rev = true, by = length)[1]
        r = copy(adj_ranges[i])
        rmin, rmax = extrema(r)
        center = (x[rmin] + x[rmax]) / 2
        binids[r] .= binid
        push!(centers, center)
        adj_ranges = _rangediff.(adj_ranges, Ref(r))
        filter!(!isempty, adj_ranges)
        binid += 1
    end
    return parent(binids), centers, idxs
end

# bin `x`s using a histogram
# we don't use StatsBase here since we want bin ids
function _bindots(
    ::Val{:histodot},
    x,
    binwidth,
    args...;
    idxs = sortperm(x),
    origin = automatic,
    closed = :left,
    kwargs...,
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
    h.isdensity && error("Histogram must not be density histogram for dotplot.")
    edges = h.edges[1]
    nbins = length(edges)
    widths = diff(edges)
    binwidth = widths[1]
    if any(w -> !isapprox(w, binwidth), widths)
        error("Histogram must have bins of equal width for dotplot.")
    end
    centers = StatsBase.midpoints(edges)
    counts = h.weights
    # make a new dataset that has the same bins
    y = [c for (c, n) in zip(centers, counts) for _ in 1:n]
    return to_plotspec(P, convert_arguments(P, y); binwidth = binwidth)
end

function convert_attribute(s::Symbol, ::key"stackdir")
    s === :right && return :up
    s === :left && return :down
    return s
end

# offset from base point in stack direction in units of markersize
# ratio is distance between centers of adjacent dots
function _stack_offsets(pos, ratio, ::Val{:up})
    return @. ratio * (pos - 1) + 1 / 2
end
function _stack_offsets(pos, ratio, ::Val{:down})
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

@inline _stack_limits(::Val{:center}, width) = (-width / 2, width)
@inline _stack_limits(::Val{:centerwhole}, width) = (-width / 2, width)
@inline _stack_limits(::Val{:up}, width) = (zero(width), width / 2)
@inline _stack_limits(::Val{:down}, width) = (-width / 2, width / 2)

function _dot_limits(x, y, width, stackdir)
    bb = xyz_boundingbox(x, y)
    T = eltype(bb)
    so, sw = _stack_limits(_maybe_val(stackdir), width)
    origin, widths = bb.origin, bb.widths
    @inbounds widths = Vec2{T}(widths[1] + sw, widths[2])
    @inbounds origin = Vec2{T}(origin[1] + so, origin[2])
    return FRect2D(origin, widths)
end

# because dot sizes depend on limits, prevent limits from counting stack heights
function data_limits(P::DotPlot{<:Tuple{X,Y}}) where {X,Y}
    @extract P (orientation, width, stackdir)
    stackdir = convert_attribute(to_value(stackdir), key"stackdir"())
    bb = _dot_limits(to_value.((P[1], P[2], width, stackdir))...)
    if ishorizontal(orientation)
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
        smooth,
        origin,
        closed,
    )

    scene = parent_scene(plot)

    outputs = lift(
        plot[1],
        plot[2],
        pixelarea(plot),
        scene.data_limits,
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
        smooth,
        origin,
        closed,
    ) do x,
    y,
    _,
    limits,
    _,
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
    smooth,
    origin,
    closed
        validate_orientation(orientation)
        stackdir = Val(convert_attribute(stackdir, key"stackdir"()))

        # set binwidth
        if binwidth === automatic
            if ishorizontal(orientation)
                limits = _flip_xy(limits)
            end
            if limits === nothing
                limits = _dot_limits(x, y, width, stackdir)
            end
            ywidth = widths(limits)[2]
            binwidth = ywidth / maxbins
        end

        # set markersize
        px_per_units = _pixels_per_units(scene)
        if ishorizontal(orientation)
            px_per_units = _flip_xy(px_per_units)
        end
        markersize = dotscale * binwidth * px_per_units[2]
        # correct for horizontal overlap due to stroke
        if strokewidth > 0
            markersize -= strokewidth
        end

        # bin data
        npoints = length(y)
        basex = float(eltype(x))[]
        basey = float(eltype(y))[]
        counts = Int[]
        binids = Int[]
        sortidxs = Vector{Int}(undef, npoints)
        j = 1
        for (groupid, xidxs) in finduniquesorted(x)
            v = view(y, xidxs)
            group_binids, group_centers, vidxs = _bindots(
                Val(method),
                v,
                binwidth,
                Val(bindir);
                smooth = smooth,
                origin = origin,
                closed = closed,
            )
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

        # make dots
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

        if ishorizontal(orientation)
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
