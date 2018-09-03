function _to_values(h::StatsBase.Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    (map(f, h.edges)..., h.weights)
end

convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram) =
    convert_arguments(P, _to_values(h)...)

plottype(::StatsBase.Histogram{<:Any, 1}) = BarPlot
plottype(::StatsBase.Histogram{<:Any, 2}) = Heatmap
plottype(::StatsBase.Histogram{<:Any, 3}) = Contour

@recipe(Histogram) do scene
    Theme()
end

function AbstractPlotting.plot!(scene::Scene, ::Type{Histogram}, attributes::Attributes, p...)
    attr = copy(attributes)
    hist_kwarg = [:nbins, :closed]
    hist_attr = [pop!(attr, key, Signal(nothing)) for key in hist_kwarg]
    h = lift(hist_attr...) do v...
        kwargs = (t for t in zip(hist_kwarg, v) if last(t) !== nothing)
        fit(StatsBase.Histogram, p...; kwargs...)
    end
    _args = lift(_to_values, h)
    args = Tuple(lift(t->t[i], _args) for i in 1:length(to_value(_args)))
    plot!(scene, plottype(to_value(h)), attr, args...)
    scene
end
