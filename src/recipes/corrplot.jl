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
    scene = Scene(scene, pixelarea(scene))
    layout = GridLayout(scene, n, n)
    for i in 1:n
        for j in 1:n
            axs = LAxis(scene)
            if i > j
                scatter!(axs, view(mat, :, j), view(mat, :, i))
                plot!(axs, linear, view(mat, :, j), view(mat, :, i))
            else
                plot!(axs, histogram, view(mat, :, j), view(mat, :, i))
            end
            layout[i,j] = axs
        end
    end
    scene
end
