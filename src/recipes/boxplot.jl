using AbstractPlotting: extrema_nan

notch_width(q2, q4, N) = 1.58 * (q4 - q2) / sqrt(N)

#=
Taken from https://github.com/JuliaPlots/StatPlots.jl/blob/master/src/boxplot.jl#L7
The StatPlots.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2016: Thomas Breloff.
=#
@recipe(BoxPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        orientation = :vertical,
        # box
        width = 0.8,
        strokecolor = :white,
        strokewidth = 0.0,
        # notch
        notch = false,
        notchwidth = 0.5,
        # median line
        show_median = true,
        mediancolor = automatic,
        medianlinewidth = 1.0,
        # whiskers
        range = 1.5, # multiple of IQR controlling whisker length
        whisker_width = :match, # match or multiple of width
        whiskercolor = :black,
        whiskerlinewidth = 1.0,
        # outliers points
        outliers = true,
        marker = :circle,
        markersize = automatic,
        outlierstrokecolor = :black,
        outlierstrokewidth = 1.0,
    )
    get!(t, :outliercolor, t[:color])
    t
end

conversion_trait(x::Type{<:BoxPlot}) = SampleBased()

_cycle(v::AbstractVector, idx::Integer) = v[mod1(idx, length(v))]
_cycle(v, idx::Integer) = v

_flip_xy(p::Point2f0) = reverse(p)
_flip_xy(r::Rect{2,T}) where {T} = Rect{2,T}(reverse(r.origin), reverse(r.widths))

function AbstractPlotting.plot!(plot::BoxPlot)
    args = @extract plot (width, range, outliers, whisker_width, notch, orientation)

    signals = lift(
        plot[1],
        plot[2],
        args...,
    ) do x, y, bw, range, outliers, whisker_width, notch, orientation
        if !(whisker_width == :match || whisker_width >= 0)
            error("whisker_width must be :match or a positive number. Found: $whisker_width")
        end
        ww = whisker_width == :match ? bw : whisker_width * bw
        outlier_points = Point2f0[]
        centers = Float32[]
        medians = Float32[]
        boxmin = Float32[]
        boxmax = Float32[]
        notchmin = Float32[]
        notchmax = Float32[]
        t_segments = Point2f0[]
        for (i, (center, idxs)) in enumerate(finduniquesorted(x))
            values = view(y, idxs)

            # compute quantiles
            q1, q2, q3, q4, q5 = quantile(values, LinRange(0, 1, 5))

            # notches
            if notch
                notchheight = notch_width(q2, q4, length(values))
                nmin, nmax = q3 - notchheight, q3 + notchheight
                push!(notchmin, nmin)
                push!(notchmax, nmax)
            end

            # outliers
            if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
                limit = range * (q4 - q2)
                inside = Float64[]
                for value in values
                    if (value < (q2 - limit)) || (value > (q4 + limit))
                        if outliers
                            push!(outlier_points, (center, value))
                        end
                    else
                        push!(inside, value)
                    end
                end
                # change q1 and q5 to show outliers
                # using maximum and minimum values inside the limits
                q1, q5 = extrema_nan(inside)
            end

            # whiskers
            HW = 0.5 * _cycle(ww, i) # Whisker width
            lw, rw = center - HW, center + HW
            push!(t_segments, (center, q2), (center, q1), (lw, q1), (rw, q1)) # lower T
            push!(t_segments, (center, q4), (center, q5), (rw, q5), (lw, q5)) # upper T

            # box
            push!(centers, center)
            push!(boxmin, q2)
            push!(medians, q3)
            push!(boxmax, q4)
        end

        # for horizontal boxplots just flip all components
        if orientation == :horizontal
            outlier_points = _flip_xy.(outlier_points)
            t_segments = _flip_xy.(t_segments)
        elseif orientation != :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end

        return (
            centers = centers,
            boxmin = boxmin,
            boxmax = boxmax,
            medians = medians,
            notchmin = notchmin,
            notchmax = notchmax,
            outliers = outlier_points,
            t_segments = t_segments,
        )
    end
    centers = @lift($signals.centers)
    boxmin = @lift($signals.boxmin)
    boxmax = @lift($signals.boxmax)
    medians = @lift($signals.medians)
    notchmin = @lift($notch ? $signals.notchmin : automatic)
    notchmax = @lift($notch ? $signals.notchmax : automatic)
    outliers = @lift($signals.outliers)
    t_segments = @lift($signals.t_segments)

    scatter!(
        plot,
        color = plot[:outliercolor],
        marker = plot[:marker],
        markersize = lift(
            (w, ms) -> ms === automatic ? w * 0.1 : ms,
            width,
            plot.markersize,
        ),
        strokecolor = plot[:outlierstrokecolor],
        strokewidth = plot[:outlierstrokewidth],
        outliers,
    )
    linesegments!(
        plot,
        color = plot[:whiskercolor],
        linewidth = plot[:whiskerlinewidth],
        t_segments,
    )
    crossbar!(
        plot,
        color = plot[:color],
        colorrange = plot[:colorrange],
        colormap = plot[:colormap],
        strokecolor = plot[:strokecolor],
        strokewidth = plot[:strokewidth],
        midlinecolor = plot[:mediancolor],
        midlinewidth = plot[:medianlinewidth],
        midline = plot[:show_median],
        orientation = orientation,
        width = width,
        notch = notch,
        notchmin = notchmin,
        notchmax = notchmax,
        notchwidth = plot[:notchwidth],
        centers,
        medians,
        boxmin,
        boxmax,
    )
end
