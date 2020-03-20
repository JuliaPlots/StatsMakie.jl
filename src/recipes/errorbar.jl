import AbstractPlotting:plot!

"""
    errorbary(x, y, Δy)

Plots points defined by `x` and `y`,
and vertical error bars (along the `y`-axis)
on those points, as defined by `Δy`.
"""
@recipe(ErrorBarY, x, y, Δy) do scene
    Theme(; default_theme(scene, LineSegments)..., whiskerwidth = 0)
end

"""
    errorbarx(x, y, Δx)

Plots points defined by `x` and `y`,
and horizontal error bars (along the `x`-axis)
on those points, as defined by `Δx`.
"""
@recipe(ErrorBarX, x, y, Δx) do scene
    Theme(; default_theme(scene, LineSegments)..., whiskerwidth = 0)
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
        whiskerwidth = 0,
        xcolor = automatic,
        xwhiskerwidth = automatic,
        ycolor = automatic,
        ywhiskerwidth = automatic,
    )
end

function plot!(plot::ErrorBarY)
    t = copy(Theme(plot))
    ww = pop!(t, :whiskerwidth)
    segments = lift(plot[1], plot[2], plot[3], ww) do x,y,Δy,ww
        bar = Pair.(Point2f0.(x, y .- Δy), Point2f0.(x, y .+ Δy))
        segments = [bar;]
        if ww != 0
            hww = ww ./ 2
            lw = Pair.(
                first.(bar) .- Point2f0.(hww, 0),
                first.(bar) .+ Point2f0.(hww, 0),
            )
            uw = Pair.(last.(bar) .- Point2f0.(hww, 0), last.(bar) .+ Point2f0.(hww, 0))
            append!(segments, [lw; uw])
        end
        return segments
    end
    linesegments!(plot, t, segments)
end

function plot!(plot::ErrorBarX)
    t = copy(Theme(plot))
    ww = pop!(t, :whiskerwidth)
    segments = lift(plot[1], plot[2], plot[3], ww) do x,y,Δx,ww
        bar = Pair.(Point2f0.(x .- Δx, y), Point2f0.(x .+ Δx, y))
        segments = [bar;]
        if ww != 0
            hww = ww ./ 2
            lw = Pair.(
                first.(bar) .- Point2f0.(0, hww),
                first.(bar) .+ Point2f0.(0, hww),
            )
            uw = Pair.(last.(bar) .- Point2f0.(0, hww), last.(bar) .+ Point2f0.(0, hww))
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
    xww, yww = pop!.(Ref(t), (:xwhiskerwidth, :ywhiskerwidth))
    xcolor = lift((xc,c) -> xc === automatic ? c : xc, xcolor, plot[:color])
    ycolor = lift((yc,c) -> yc === automatic ? c : yc, ycolor, plot[:color])
    xww = lift((xww,ww) -> xww === automatic ? ww : xww, xww, plot[:whiskerwidth])
    yww = lift((yww,ww) -> yww === automatic ? ww : yww, yww, plot[:whiskerwidth])

    #x-error
    tx = merge(Theme(color = xcolor, whiskerwidth = xww), t)
    errorbarx!(plot, tx, x, y, Δx)
    #y-error
    ty = merge(Theme(color = ycolor, whiskerwidth = yww), t)
    errorbary!(plot, ty, x, y, Δy)
    plot
end
