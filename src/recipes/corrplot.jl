# From Makie examples

@recipe(CorrPlot) do scene
    Theme(
        link = :x,  # need custom linking for y
        legend = false,
        margin = 1,
        fillcolor = theme(scene, :color),
        linecolor = theme(scene, :color),
        # indices = reshape(1:n^2, n, n)',
        title = "",
    )
end

AbstractPlotting.convert_arguments(::Type{<: CorrPlot}, x) = (x,)

function AbstractPlotting.plot!(scene::Scene, ::Type{CorrPlot}, attributes::Attributes, mat)
    n = size(mat, 2)
    layout = GridLayout(scene, n, n)
    layout[1:n, 1:n] = axs = [LAxis(scene) for i in 1:n, j in 1:n]

    for i in 1:n
        for j in 1:n
            ax = axs[i, j]
            if i > j
                scatter!(ax, view(mat, :, j), view(mat, :, i))
                plot!(ax, linear, view(mat, :, j), view(mat, :, i))
            elseif i == j
                plot!(ax, histogram, view(mat, :, j))
            else
                plot!(ax, histogram, view(mat, :, j), view(mat, :, i))
            end
        end
    end

    tight_ticklabel_spacing!.(axs)

    return scene
end
