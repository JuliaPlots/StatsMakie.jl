function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    convert_arguments(P, map(f, h.edges)..., h.weights)
end

plottype(::StatsBase.Histogram{<:Any, 1}) = BarPlot
plottype(::StatsBase.Histogram{<:Any, 2}) = Heatmap
plottype(::StatsBase.Histogram{<:Any, 3}) = Contour

@recipe(Histogram) do scene
    Theme()
end

function plot!(scene::SceneLike, ::Type{<:Histogram}, attributes::Attributes, p...)
    hist_attr, attr = splitattributes(attributes, [:nbins, :closed])
    h = LiftedKwargs(hist_attr)(fit, StatsBase.Histogram, p...)
    plot!(scene, attr, h)
    scene
end
