@recipe(Violin) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both
    )
end

function plot!(plot::Violin)
    width, side = plot[:width], plot[:side]

    bigmesh = lift(plot[1], plot[2], width) do x, y, bw
        t = table((x = x, y = y), copy = false, presorted = true)
        gt = groupby(kde, t, :x, select = :y)
        meshes = GeometryTypes.GLPlainMesh[]
        for row in rows(gt)
            min, max = extrema_nan(row.kde.density)
            x = row.x .+ row.kde.density .* (bw/max)
            y = row.kde.x
            mesh = GeometryTypes.GLPlainMesh.(Point2f0.(x, y))
            push!(meshes, mesh)
        end
        return merge(meshes...)
    end

    mesh!(bigmesh)
end
