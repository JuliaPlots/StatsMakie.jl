@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both,
        width = 0.8,
        mediancolor = :white,
        show_median = false
    )
end

function plot!(plot::Violin)
    width, side = plot[:width], plot[:side]

    signals = lift(plot[1], plot[2], width, side) do x, y, bw, vside
        meshes = GeometryTypes.GLPlainMesh[]
        lines = Pair{Point2f0, Point2f0}[]
        for (key, idxs) in finduniquesorted(x)
            v = view(y, idxs)
            spec = (x = key, kde = kde(v), median = median(v))
            min, max = extrema_nan(spec.kde.density)
            xl = reverse(spec.x .- spec.kde.density .* (0.5*bw/max))
            xr = spec.x .+ spec.kde.density .* (0.5*bw/max)
            yl = reverse(spec.kde.x)
            yr = spec.kde.x

            x_coord = vside == :left ? xl : vside == :right ? xr : vcat(xr, xl)
            y_coord = vside == :left ? yl : vside == :right ? yr : vcat(yr, yl)
            mesh = GeometryTypes.GLPlainMesh(Point2f0.(x_coord, y_coord))
            push!(meshes, mesh)
            median_left = Point2f0(vside == :right ? spec.x : spec.x-(0.5*bw), spec.median)
            median_right = Point2f0(vside == :left ? spec.x : spec.x+(0.5*bw), spec.median)
            push!(lines, median_left => median_right)
        end
        return meshes, lines
    end
    mesh!(plot, lift(first, signals), color = plot[:color], visible = plot[:visible])
    linesegments!(plot, lift(last, signals), color = plot[:mediancolor], visible = plot[:show_median])
end
