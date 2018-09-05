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
    C = cor(mat)
    plotgrid = broadcast(1:n, (1:n)') do i, j
        vi = view(mat, :, i)
        vj = view(mat, :, j)
        s = Scene(scene, Reactive.value(pixelarea(scene)))
        if i == j # histograms are on the diagonal
            histogram!(s, vi)
        elseif i > j
            scatter!(s, vj, vi)
        else
            scatter!(s, vj, vi)
        end
        s
    end
    grid!(scene, plotgrid)
    scene
end
