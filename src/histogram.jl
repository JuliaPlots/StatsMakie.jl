function hist2values(h::StatsBase.Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    (map(f, h.edges)..., h.weights)
end

convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram) =
    convert_arguments(P, hist2values(h)...)

plottype(::StatsBase.Histogram{<:Any, 1}) = BarPlot
plottype(::StatsBase.Histogram{<:Any, 2}) = Heatmap
plottype(::StatsBase.Histogram{<:Any, 3}) = Contour

@recipe(Histogram) do scene
    Theme()
end

# From the StatPlots examples in Makie

function AbstractPlotting.plot!(scene::Scene, ::Type{Histogram}, attributes::Attributes, p...)
    # we assume that the y kwarg is set with the data to be binned, and nbins is also defined
    attr = copy(attributes)
    hist_attr = [pop!(attr, key, Signal(nothing)) for key in [:nbins, :closed]]
    h = lift(hist_attr...) do nbins, closed
        kwargs = (nbins = nbins, closed = closed)
        fit(StatsBase.Histogram, p...; Iterators.filter(t -> last(t) !== nothing, pairs(kwargs))...)
    end
    _args = lift(hist2values, h)
    args = Tuple(lift(t->t[i], _args) for i in 1:length(to_value(_args)))
    plot!(scene, plottype(to_value(h)), attr, args...)
    scene
end
