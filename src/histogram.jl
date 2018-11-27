export histogram

const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

to_weights(v) = StatsBase.weights(v)
to_weights(v::StatsBase.AbstractWeights) = v

function _histogram(args...; edges = automatic, weights = automatic, kwargs...)
    ea = edges === automatic ? () : (edges,)
    wa = weights === automatic ? () : (to_weights(weights),)
    ha = length(args) == 1 ? args[1] : args
    fit(StatsBase.Histogram, ha, wa..., ea...; kwargs...)
end

const histogram = Analysis(_histogram)
