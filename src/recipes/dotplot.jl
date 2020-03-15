using AbstractPlotting: parent_scene, xyz_boundingbox

@recipe(DotPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        alpha = 1,
        strokecolor = :black,
        strokewidth = 0,
        orientation = :vertical,
        side = :both,
        stackratio = 1,
        dotscale = 1,
        binwidth = automatic,
        nbins = 30,
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

function convert_attribute(s::Symbol, ::key"side")
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
function _stack_offsets(pos, ratio, ::Val{:both})
    n = length(pos)
    return @. ratio * (pos - (n + 1) / 2)
end
function _stack_offsets(pos, ratio, ::Val{:bothaligned})
    n = length(pos)
    return @. ratio * (pos - floor((n + 1) / 2)) + 1 / 2
end

@inline _stack_limits(::Val{:both}, width) = (-width / 2, width)
@inline _stack_limits(::Val{:bothaligned}, width) = (-width / 2, width)
@inline _stack_limits(::Val{:up}, width) = (zero(width), width / 2)
@inline _stack_limits(::Val{:down}, width) = (-width / 2, width / 2)

function _dot_limits(x, y, width, side)
    bb = xyz_boundingbox(x, y)
    T = eltype(bb)
    so, sw = _stack_limits(_maybe_val(side), width)
    origin, widths = bb.origin, bb.widths
    @inbounds widths = Vec2{T}(widths[1] + sw, widths[2])
    @inbounds origin = Vec2{T}(origin[1] + so, origin[2])
    return FRect2D(origin, widths)
end

function AbstractPlotting.plot!(plot::DotPlot)
    @extract plot (
        alpha,
        color,
        strokecolor,
        strokewidth,
        orientation,
        side,
        binwidth,
        nbins,
        method,
        bindir,
        smooth,
        origin,
        closed,
    )

    scene = parent_scene(plot)

    stackspec = lift(
        plot[1],
        plot[2],
        scene.data_limits,
        scene.padding,
        orientation,
        side,
        binwidth,
        nbins,
        method,
        bindir,
        smooth,
        origin,
        closed,
    ) do x,
    y,
    limits,
    _,
    orientation,
    side,
    binwidth,
    nbins,
    method,
    bindir,
    smooth,
    origin,
    closed
        validate_orientation(orientation)
        side = Val(convert_attribute(side, key"side"()))
        method = Val(method)
        bindir = Val(bindir)

        xgroups = finduniquesorted(x)

        # set binwidth
        if binwidth === automatic
            if ishorizontal(orientation)
                limits = _flip_xy(limits)
            end
            if limits === nothing
                limits = _dot_limits(x, y, 0, side)
            end
            ywidth = widths(limits)[2]

            if nbins !== automatic
                binwidth = ywidth / nbins
            end
        end

        # bin data
        npoints = length(y)
        basex = float(eltype(x))[]
        basey = float(eltype(y))[]
        counts = Int[]
        sortidxs = Vector{Int}(undef, npoints)
        for (groupid, xidxs) in xgroups
            v = view(y, xidxs)
            tallies = fit(
                Tallies,
                v,
                method;
                binwidth = binwidth,
                bindir = bindir,
                smooth = smooth,
                origin = origin,
                closed = closed,
            )
            append!(basex, fill(groupid, length(tallies.positions)))
            append!(basey, tallies.positions)
            append!(counts, tallies.counts)
        end

        if ishorizontal(orientation)
            stackdim = 2
            basex, basey = basey, basex
        else
            stackdim = 1
        end

        return (
            x = basex,
            y = basey,
            counts = counts,
            markersize = binwidth,
            stackdim = stackdim,
        )
    end
    x = @lift($stackspec.x)
    y = @lift($stackspec.y)
    counts = @lift($stackspec.counts)
    markersize = @lift($stackspec.markersize)
    stackdim = @lift($stackspec.stackdim)

    stacks!(
        plot,
        x,
        y,
        counts;
        markersize = markersize,
        stackdim = stackdim,
        alpha = alpha,
        color = color,
        strokecolor = strokecolor,
        strokewidth = strokewidth,
    )
end
