@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both,
        width = automatic
    )
end

function plot!(plot::Violin)
    width, side = plot[:width], plot[:side]

    bigmesh = lift(plot[1], plot[2], width, side) do x, y, bw, vside
        t = table((x = x, y = y), copy = false, presorted = true)
        gt = groupby(kde, t, :x, select = :y)
        bw === automatic && (bw = minimum(diff(column(gt, :x))))
        meshes = GeometryTypes.GLPlainMesh[]
        for row in rows(gt)
            min, max = extrema_nan(row.kde.density)
            xl = reverse(row.x .- row.kde.density .* (0.4*bw/max))
            xr = row.x .+ row.kde.density .* (0.4*bw/max)
            yl = reverse(row.kde.x)
            yr = row.kde.x

            x = vside == :left ? xl : vside == :right ? xr : vcat(xr, xl)
            y = vside == :left ? yl : vside == :right ? yr : vcat(yr, yl)
            mesh = GeometryTypes.GLPlainMesh(Point2f0.(x, y))
            push!(meshes, mesh)
        end
        return merge(meshes)
    end

    mesh!(plot, bigmesh)
end
