@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both,
        width = 0.8,
        strokecolor = :white,
        show_median = false,
        mediancolor = automatic,
        medianlinewidth = 1.0,
    )
end

conversion_trait(x::Type{<:Violin}) = SampleBased()

function plot!(plot::Violin)
    width, side, show_median = plot[:width], plot[:side], plot[:show_median]

    signals = lift(plot[1], plot[2], width, side, show_median) do x, y, bw, vside, show_median
        vertices = Vector{Point2f0}[]
        lines = Pair{Point2f0, Point2f0}[]
        for (key, idxs) in finduniquesorted(x)
            v = view(y, idxs)
            spec = (x = key, kde = kde(v), median = median(v))
            min, max = extrema_nan(spec.kde.density)
            scale = 0.5*bw/max
            xl = reverse(spec.x .- spec.kde.density .* scale)
            xr = spec.x .+ spec.kde.density .* scale
            yl = reverse(spec.kde.x)
            yr = spec.kde.x

            x_coord = vside == :left ? xl : vside == :right ? xr : vcat(xr, xl)
            y_coord = vside == :left ? yl : vside == :right ? yr : vcat(yr, yl)
            verts = Point2f0.(x_coord, y_coord)
            push!(vertices, verts)

            if show_median
                # interpolate median bounds between corresponding points
                xm = spec.median
                ip = findfirst(>(xm), spec.kde.x)
                ym₋, ym₊ = spec.kde.density[ip-1], spec.kde.density[ip]
                xm₋, xm₊ = spec.kde.x[ip-1], spec.kde.x[ip]
                ym = (xm * (ym₊ - ym₋) + xm₊ * ym₋ - xm₋ * ym₊) / (xm₊ - xm₋)
                median_left = Point2f0(vside == :right ? spec.x : spec.x - ym * scale, xm)
                median_right = Point2f0(vside == :left ? spec.x : spec.x + ym * scale, xm)
                push!(lines, median_left => median_right)
            end
        end
        return vertices, lines
    end
    t = copy(Theme(plot))
    mediancolor = pop!(t, :mediancolor)
    poly!(plot, t, lift(first, signals))
    linesegments!(
        plot,
        lift(last, signals),
        color = lift(
            (mc, sc) -> mc === automatic ? sc : mc,
            mediancolor,
            plot[:strokecolor],
        ),
        linewidth = plot[:medianlinewidth],
        visible = plot[:show_median],
    )
end
