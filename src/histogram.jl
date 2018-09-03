function convert_arguments(P::Type{<:AbstractPlot}, h::Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    xs = map(f, h.edges)
    convert_arguments(P, xs..., h.weights)
end

plottype(::Histogram{<:Any, 1}) = BarPlot
plottype(::Histogram{<:Any, 2}) = Heatmap
