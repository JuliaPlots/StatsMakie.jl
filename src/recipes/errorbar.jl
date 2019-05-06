import AbstractPlotting:plot!

@recipe(ErrorBarY, x, y, Δy) do scene
    Theme(
          color = :black
         )
end

@recipe(ErrorBarX, x, y, Δx) do scene
    Theme(
          color = :black
         )
end

@recipe(ErrorBar, x, y, Δx, Δy) do scene
    Theme(
          xcolor = :black,
          ycolor = :black
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
