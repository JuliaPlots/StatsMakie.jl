import AbstractPlotting:plot!

"""
    errorbary(x, y, ymin, ymax)
    errorbary(x, y, Δy)

Plots points defined by `x` and `y`,
and vertical error bars (along the `y`-axis)
on those points, as defined by `Δy`.
"""
@recipe(ErrorBarY, x, ymin, ymax) do scene
    Theme(; default_theme(scene, LineSegments)..., whisker_width = 0)
end

"""
    errorbarx(x, y, xmin, xmax)
    errorbarx(x, y, Δx)

Plots points defined by `x` and `y`,
and horizontal error bars (along the `x`-axis)
on those points, as defined by `Δx`.
"""
@recipe(ErrorBarX, x, y, xmin, xmax) do scene
    Theme(; default_theme(scene, LineSegments)..., whisker_width = 0)
end

"""
    errorbar(x, y, xmin, xmax, ymin, ymax)
    errorbar(x, y, Δx, Δy)

Plots points defined by `x` and `y`,
and horizontal and vertical error bars
(along the `x` and `y`-axes)
on those points, as defined by `Δx` and `Δy`.
"""
@recipe(ErrorBar, x, y, xmin, xmax, ymin, ymax) do scene
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
    t = copy(Theme(plot))
    ww = pop!(t, :whisker_width)
    @extract plot (x, ymin, ymax)
    segments = lift(plot[1], plot[2], plot[3], ww) do x,ymin,ymax,ww
        bar = Pair.(Point2f0.(x, ymin), Point2f0.(x, ymax))
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
    ww = pop!(t, :whisker_width)
    segments = lift(plot[1], plot[2], plot[3], plot[4], ww) do x,y,xmin,xmax,ww
        bar = Pair.(Point2f0.(xmin, y), Point2f0.(xmax, y))
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
    x,y,xmin,xmax,ymin,ymax = (plot[1], plot[2], plot[3], plot[4], plot[5], plot[6])

    t = copy(Theme(plot))
    xcolor, ycolor = pop!.(Ref(t), (:xcolor, :ycolor))
    xww, yww = pop!.(Ref(t), (:xwhisker_width, :ywhisker_width))
    xcolor = lift((xc,c) -> xc === automatic ? c : xc, xcolor, plot[:color])
    ycolor = lift((yc,c) -> yc === automatic ? c : yc, ycolor, plot[:color])
    xww = lift((xww,ww) -> xww === automatic ? ww : xww, xww, plot[:whisker_width])
    yww = lift((yww,ww) -> yww === automatic ? ww : yww, yww, plot[:whisker_width])

    #x-error
    tx = merge(Theme(color = xcolor, whisker_width = xww), t)
    errorbarx!(plot, tx, x, y, xmin, xmax)
    #y-error
    ty = merge(Theme(color = ycolor, whisker_width = yww), t)
    errorbary!(plot, ty, x, y, ymin, ymax)
    plot
end

const ErrorBarXorY = Union{ErrorBarX,ErrorBarY}

# convert_arguments(T::Type{<:ErrorBarX}, x, y, Δx) = (x, y, x .- Δx, x .+ Δx)
# function convert_arguments(T::Type{<:ErrorBarX}, x, y, xminmax::NTuple{2})
#     return (x, y, first.(xminmax), last.(xminmax))
# end
convert_arguments(T::Type{<:ErrorBarY}, x, y, Δy) = (x, y, y .- Δy, y .+ Δy)
convert_arguments(T::Type{<:ErrorBarY}, x, yrange::AbstractPlotting.Interval) = (x, yrange.left, yrange.right)
function convert_arguments(T::Type{<:ErrorBarY}, x, y, yrange::NTuple{2})
    return (x, y, first.(yminmax), last.(yminmax))
end
function convert_arguments(T::Type{<:ErrorBar}, x, y, Δx, Δy)
    return (convert_arguments(ErrorBarX, x, y, Δx)..., convert_arguments(ErrorBarY, x, y, Δy)[3:end]...)
end
