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

function _centers_counts(x, lowers, uppers; func = _outermean)
    nbins = length(uppers)
    centers = Vector{eltype(x)}(undef, nbins)
    T = Base.promote_eltype(lowers, uppers)
    counts = Vector{T}(undef, nbins)
    @inbounds for i in eachindex(lowers, uppers)
        l, u = lowers[i], uppers[i]
        centers[i] = func(x, l, u)
        counts[i] = u - l + 1
    end
    return centers, counts
end

# Bin data points according to Wilkinson
function _bindots(x, binwidth, bindir = Val(:lefttoright); sorted = false)
    x = sorted ? x : sort(x)
    uppers, lowers = Int[], [1]
    binend = @inbounds x[1] + binwidth
    n = length(x)
    for i = 2:n
        @inbounds if x[i] ≥ binend
            push!(uppers, i - 1)
            push!(lowers, i)
            binend = x[i] + binwidth
        end
    end
    push!(uppers, n)
    centers, counts = _centers_counts(x, lowers, uppers)
    return centers, counts
end
function _bindots(x, binwidth, ::Val{:righttoleft}; kwargs...)
    x = reverse(-x)
    centers, counts = _bindots(x, binwidth, Val(:lefttoright); kwargs...)
    return reverse(-centers), counts
end

_stack_offset(ndots, ::Val{:center}) = -ndots / 2
_stack_offset(ndots, ::Val{:centerwhole}) = -ceil(ndots / 2)
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
    orientation, stackdir, width = @extract P (orientation, stackdir, width)
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
    args = @extract plot (
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
        binwidth,
        maxbins,
        bindir,
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
    bindir
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

        data_width = widths(new_limits)[2] - width
        if binwidth === automatic
            data_width = widths(new_limits)[2] - width
            binwidth = data_width / maxbins
        end

        pos_centers_counts = map(finduniquesorted(x)) do p
            key, idxs = p
            v = view(y, idxs)
            sortv = sort(v)
            centers, counts = _bindots(sortv, binwidth, bindir; sorted = true)
            return key => zip(centers, counts)
        end

        xywidthtot = xywidth .* (1 .+ 2 .* padding)
        pxperunit = xywidthpx ./ xywidthtot
        markersize = dotscale * binwidth * pxperunit[2]
        dotwidth = markersize / pxperunit[1]
        scaleddotwidth = stackratio * dotwidth

        dotx = Float32[]
        doty = Float32[]
        for (xpos, centers_counts) in pos_centers_counts
            for (c, n) in centers_counts
                offset = _stack_offset(n, stackdir)
                append!(dotx, xpos .+ scaleddotwidth .* ((1:n) .- 1 / 2 .+ offset))
                append!(doty, fill(c, n))
            end
        end

        if orientation == :horizontal
            dotx, doty = doty, dotx
        end

        return dotx, doty, markersize * px
    end
    dotx = @lift($outputs[1])
    doty = @lift($outputs[2])
    markersize = @lift($outputs[3])

    scatter!(
        plot,
        dotx,
        doty;
        markersize = markersize,
        color = color,
        alpha = alpha,
        strokecolor = strokecolor,
        strokewidth = strokewidth,
    )
end
