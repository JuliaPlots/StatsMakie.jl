import AbstractPlotting:plot!

"""
    errorbary(x, y, Δy)

Plots points defined by `x` and `y`,
and vertical error bars (along the `y`-axis)
on those points, as defined by `Δy`.
"""
@recipe(ErrorBarY, x, y, Δy) do scene
    Theme(
          color = theme(scene, :color)
         )
end

"""
    errorbarx(x, y, Δx)

Plots points defined by `x` and `y`,
and horizontal error bars (along the `x`-axis)
on those points, as defined by `Δx`.
"""
@recipe(ErrorBarX, x, y, Δx) do scene
    Theme(
          color = theme(scene, :color)
         )
end

"""
    errorbar(x, y, Δx, Δy)

Plots points defined by `x` and `y`,
and horizontal and vertical error bars 
(along the `x` and `y`-axes)
on those points, as defined by `Δx` and `Δy`.
"""
@recipe(ErrorBar, x, y, Δx, Δy) do scene
    Theme(
          xcolor = theme(scene, :color),
          ycolor = theme(scene, :color)
         )
end

function plot!(plot::ErrorBarY)
    segments = map(plot[1], plot[2], plot[3]) do x,y,Δy
        [Point2f0(x[i], y[i]-Δy[i])=>Point2f0(x[i], y[i]+Δy[i]) for i in 1:length(x)]
    end
    linesegments!(plot, segments, color=plot[:color])
end

function plot!(plot::ErrorBarX)
    segments = map(plot[1], plot[2], plot[3]) do x,y,Δx
        [Point2f0(x[i]-Δx[i], y[i])=>Point2f0(x[i]+Δx[i], y[i]) for i in 1:length(x)]
    end
    linesegments!(plot, segments, color=plot[:color])
end

function plot!(plot::ErrorBar)
    x,y,Δx,Δy = (plot[1], plot[2], plot[3], plot[4])
    #x-error
    errorbarx!(plot, x, y, Δx, color=plot[:xcolor])
    #y-error
    errorbary!(plot, x, y, Δy, color=plot[:ycolor])
    plot
end
