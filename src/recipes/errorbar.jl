import AbstractPlotting:plot!

"""
    errorbary(x, y, Δy)

Plots points defined by `x` and `y`,
and vertical error bars (along the `y`-axis)
on those points, as defined by `Δy`.
"""
@recipe(ErrorBarY, x, y, Δy) do scene
    default_theme(scene, LineSegments)
end

"""
    errorbarx(x, y, Δx)

Plots points defined by `x` and `y`,
and horizontal error bars (along the `x`-axis)
on those points, as defined by `Δx`.
"""
@recipe(ErrorBarX, x, y, Δx) do scene
    default_theme(scene, LineSegments)
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
        xcolor = automatic,
        ycolor = automatic
    )
end

function plot!(plot::ErrorBarY)
    segments = map(plot[1], plot[2], plot[3]) do x,y,Δy
        [Point2f0(x[i], y[i]-Δy[i])=>Point2f0(x[i], y[i]+Δy[i]) for i in 1:length(x)]
    end
    linesegments!(plot, Theme(plot), segments)
end

function plot!(plot::ErrorBarX)
    segments = map(plot[1], plot[2], plot[3]) do x,y,Δx
        [Point2f0(x[i]-Δx[i], y[i])=>Point2f0(x[i]+Δx[i], y[i]) for i in 1:length(x)]
    end
    linesegments!(plot, Theme(plot), segments)
end

function plot!(plot::ErrorBar)
    x,y,Δx,Δy = (plot[1], plot[2], plot[3], plot[4])

    t = copy(Theme(plot))
    xcolor, ycolor = pop!.(Ref(t), (:xcolor, :ycolor))
    xcolor = lift((xc,c) -> xc === automatic ? c : xc, xcolor, plot[:color])
    ycolor = lift((yc,c) -> yc === automatic ? c : yc, ycolor, plot[:color])

    #x-error
    tx = merge(Theme(color = xcolor), t)
    errorbarx!(plot, tx, x, y, Δx)
    #y-error
    ty = merge(Theme(color = ycolor), t)
    errorbary!(plot, ty, x, y, Δy)
    plot
end
