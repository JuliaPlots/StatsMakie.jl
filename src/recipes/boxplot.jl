using AbstractPlotting: extrema_nan

notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

pair_up(dict, key) = (key => dict[key])

#=
Taken from https://github.com/JuliaPlots/StatPlots.jl/blob/master/src/boxplot.jl#L7
The StatPlots.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2016: Thomas Breloff.
=#
@recipe(BoxPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        notch = false,
        range = 1.5,
        outliers = true,
        whisker_width = :match,
        width = 0.8,
        markershape = :circle,
        strokecolor = :black,
        strokewidth = 1.0,
        mediancolor = :white,
        show_median = true,
    )
    t[:outliercolor] = t[:color]
    t
end

_cycle(v::AbstractVector, idx::Integer) = v[mod1(idx, length(v))]
_cycle(v, idx::Integer) = v

function AbstractPlotting.plot!(plot::BoxPlot)
    args = @extract plot (width, range, outliers, whisker_width, notch)

    signals = lift(plot[1], plot[2], args...) do x, y, bw, range, outliers, whisker_width, notch
        glabels = sort(collect(unique(x)))
        warning = false
        outlier_points = Point2f0[]
        if !(whisker_width == :match || whisker_width >= 0)
            error("whisker_width must be :match or a positive number. Found: $whisker_width")
        end
        ww = whisker_width == :match ? bw : whisker_width
        boxes = FRect2D[]
        notched_boxes = Vector{Point2f0}[]
        t_segments = Point2f0[]
        medians = Point2f0[]
        for (i, glabel) in enumerate(glabels)
            # filter y
            values = y[filter(i -> _cycle(x, i) == glabel, 1:length(y))]
            # compute quantiles
            q1, q2, q3, q4, q5 = quantile(values, LinRange(0, 1, 5))
            # notch
            n = notch_width(q2, q4, length(values))
            # warn on inverted notches?
            if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
                @warn("Boxplot's notch went outside hinges. Set notch to false.")
                warning = true # Show the warning only one time
            end

            # make the shape
            center = glabel
            hw = 0.5 * _cycle(bw, i) # Box width
            HW = 0.5 * _cycle(ww, i) # Whisker width
            l, m, r = center - hw, center, center + hw
            lw, rw = center - HW, center + HW

            # internal nodes for notches
            L, R = center - 0.5 * hw, center + 0.5 * hw

            # outliers
            if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
                limit = range*(q4-q2)
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
            push!(t_segments, (m, q2), (m, q1), (l, q1), (r, q1))# lower T
            push!(t_segments, (m, q4), (m, q5), (r, q5), (l, q5))# upper T
            # Box
            if notch
                push!(notched_boxes, map(Point2f0, [(l,q2),(r,q2),(r, q2 + n/2),(R, q3), (r, q4-n/2) , (r, q4), (l, q4), (l, q4-n/2), (L, q3), (l, q2+n/2), (l,q2)]))
                # push!(boxes, FRect(l, q4, hw, n)) # lower box
                push!(medians, (L, q3), (R, q3))
            else
                push!(boxes, FRect(l, q2, 2hw, (q4 - q2)))
                push!(medians, (l, q3), (r, q3))
            end
        end
        if notch
            return notched_boxes, outlier_points, medians, t_segments
        end
        return boxes, outlier_points, medians, t_segments
    end
    outliers = lift(getindex, signals, Node(2))
    medians = lift(getindex, signals, Node(3))
    boxes = lift(getindex, signals, Node(1))
    t_segments = lift(last, signals)
    scatter!(
        plot,
        color = plot[:outliercolor],
        strokecolor = plot[:strokecolor],
        markersize = lift(*, width, 0.1),
        strokewidth = plot[:strokewidth],
        outliers,
    )
    linesegments!(
        plot,
        color = plot[:strokecolor],
        linewidth = plot[:strokewidth],
        t_segments,
    )
    poly!(
        plot,
        color = plot[:color],
        boxes,
    )
    linesegments!(
        plot,
        color = plot[:mediancolor],
        visible = plot[:show_median],
        medians,
    )
end
