import AbstractPlotting:plot!

"""
    errorbary(x, y, Δy)

Plots points defined by `x` and `y`,
and vertical error bars (along the `y`-axis)
on those points, as defined by `Δy`.
"""
@recipe(ErrorBarY, x, y, Δy) do scene
    Theme(; default_theme(scene, LineSegments)..., whisker_width = 0)
end

"""
    errorbarx(x, y, Δx)

Plots points defined by `x` and `y`,
and horizontal error bars (along the `x`-axis)
on those points, as defined by `Δx`.
"""
@recipe(ErrorBarX, x, y, Δx) do scene
    Theme(; default_theme(scene, LineSegments)..., whisker_width = 0)
end

"""
    errorbar(x, y, Δx, Δy)

Plots points defined by `x` and `y`,
and horizontal and vertical error bars
(along the `x` and `y`-axes)
on those points, as defined by `Δx` and `Δy`.
"""
@recipe(ErrorBar, x, y, Δx, Δy) do scene
    Theme(;
        default_theme(scene, LineSegments)...,
        whisker_width = 0,
        xcolor = automatic,
        xwhisker_width = automatic,
        ycolor = automatic,
        ywhisker_width = automatic,
    )
end

function plot!(plot::ErrorBarY)
    t = Theme(plot)
    ww = pop!(t, :whisker_width)
    segments = lift(plot[1], plot[2], plot[3], ww) do x,y,Δy,ww
        bar = Pair.(Point2f0.(x, y .- Δy), Point2f0.(x, y .+ Δy))
        segments = [bar;]
        if ww != 0
            lw = Pair.(first.(bar) .- Point2f0.(ww, 0), first.(bar) .+ Point2f0.(ww, 0))
            uw = Pair.(last.(bar) .- Point2f0.(ww, 0), last.(bar) .+ Point2f0.(ww, 0))
            append!(segments, [lw; uw])
        end
        return segments
    end
    linesegments!(plot, t, segments)
end

function plot!(plot::ErrorBarX)
    t = Theme(plot)
    ww = pop!(t, :whisker_width)
    segments = lift(plot[1], plot[2], plot[3], ww) do x,y,Δx,ww
        bar = Pair.(Point2f0.(x .- Δx, y), Point2f0.(x .+ Δx, y))
        segments = [bar;]
        if ww != 0
            lw = Pair.(first.(bar) .- Point2f0.(0, ww), first.(bar) .+ Point2f0.(0, ww))
            uw = Pair.(last.(bar) .- Point2f0.(0, ww), last.(bar) .+ Point2f0.(0, ww))
            append!(segments, [lw; uw])
        end
        return segments
    end
    linesegments!(plot, t, segments)
end

function plot!(plot::ErrorBar)
    x,y,Δx,Δy = (plot[1], plot[2], plot[3], plot[4])

    t = copy(Theme(plot))
    xcolor, ycolor = pop!.(Ref(t), (:xcolor, :ycolor))
    xww, yww = pop!.(Ref(t), (:xwhisker_width, :ywhisker_width))
    xcolor = lift((xc,c) -> xc === automatic ? c : xc, xcolor, plot[:color])
    ycolor = lift((yc,c) -> yc === automatic ? c : yc, ycolor, plot[:color])
    xww = lift((xww,ww) -> xww === automatic ? ww : xww, xww, plot[:whisker_width])
    yww = lift((yww,ww) -> yww === automatic ? ww : yww, yww, plot[:whisker_width])

    #x-error
    tx = merge(Theme(color = xcolor, whisker_width = xww), t)
    errorbarx!(plot, tx, x, y, Δx)
    #y-error
    ty = merge(Theme(color = ycolor, whisker_width = yww), t)
    errorbary!(plot, ty, x, y, Δy)
    plot
end
