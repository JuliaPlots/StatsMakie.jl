@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both,
        width = automatic,
        linecolor = :black,
        show_median = false
    )
end

function plot!(plot::Violin)
    width, side = plot[:width], plot[:side]

    signals = lift(plot[1], plot[2], width, side) do x, y, bw, vside
        t = table((x = x, y = y), copy = false, presorted = true)
        gt = groupby(v -> (kde = kde(v), median = median(v)), t, :x, select = :y)
        bw === automatic && (bw = minimum(diff(column(gt, :x))))
        polys = Vector{Point2f0}[]
        lines = Pair{Point2f0, Point2f0}[]
        for row in rows(gt)
            min, max = extrema_nan(row.kde.density)
            xl = reverse(row.x .- row.kde.density .* (0.4*bw/max))
            xr = row.x .+ row.kde.density .* (0.4*bw/max)
            yl = reverse(row.kde.x)
            yr = row.kde.x

            x = vside == :left ? xl : vside == :right ? xr : vcat(xr, xl)
            y = vside == :left ? yl : vside == :right ? yr : vcat(yr, yl)
            push!(polys, Point2f0.(x, y))
            median_left = Point2f0(vside == :right ? row.x : row.x-(0.4*bw), row.median)
            median_right = Point2f0(vside == :left ? row.x : row.x+(0.4*bw), row.median)
            push!(lines, median_left => median_right)
        end
        return polys, lines
    end
    ploy!(plot, lift(first, signals), color = plot[:color], visible = plot[:visible])
    linesegments!(plot, lift(last, signals), color = plot[:linecolor], visible = plot[:show_median])
end
