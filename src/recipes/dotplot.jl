using AbstractPlotting: data_limits, parent_scene

@recipe(DotPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        alpha = 1,
        strokecolor = :black,
        strokewidth = 0,
        orientation = :vertical,
        stackdir = :center,
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

function _widths(limits, dlimits, x, y)
    limits === nothing || return widths(limits)[1:2]
    dlimits === nothing || return widths(dlimits)[1:2]
    xmin, xmax = extrema(x)
    ymin, ymax = extrema(y)
    return [xmax - xmin, ymax - ymin]
end

_stack_offset(ndots, ::Val{:center}) = -ndots / 2
_stack_offset(ndots, ::Val{:centerwhole}) = -ceil(ndots / 2)
_stack_offset(ndots, ::Val{:up}) = zero(ndots)
_stack_offset(ndots, ::Union{Val{:up},Val{:left}}) = zero(ndots)
_stack_offset(ndots, ::Union{Val{:down},Val{:right}}) = -ndots

_flip_xy(::Nothing) = nothing
_flip_xy(r::Rect{N,T}) where {N,T} = _flip_xy(Rect{2,T}(r))
_flip_xy(v::AbstractVector) = reverse(v[1:2])

function AbstractPlotting.plot!(plot::DotPlot)
    args = @extract plot (
        color,
        alpha,
        strokecolor,
        strokewidth,
        orientation,
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
        stackdir,
        stackratio,
        dotscale,
        binwidth,
        maxbins,
        bindir,
    ) do x,
    y,
    limits,
    area,
    padding,
    orientation,
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
        dlimits = data_limits(scene)

        if orientation == :horizontal
            padding = _flip_xy(padding)
            xywidthpx = _flip_xy(xywidthpx)
            limits = _flip_xy(limits)
            dlimits = _flip_xy(dlimits)
        elseif orientation != :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end

        xywidth = _widths(limits, dlimits, x, y)

        binwidth = binwidth === automatic ? xywidth[2] / maxbins : binwidth

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
        dotwidth = markersize / pxperunit[1] # TODO: fix when one group is plotted
        scaleddotwidth = stackratio * dotwidth

        dotx = Float32[]
        doty = Float32[]
        for (xpos, centers_counts) in pos_centers_counts
            for (c, n) in centers_counts
                offset = _stack_offset(n, stackdir)
                append!(dotx, xpos .+ dotwidth .* ((1:n) .- 1 / 2 .+ offset))
                append!(doty, repeat([c], n))
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
