export histogram

const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

function  histogram(args...; edges = automatic, kwargs...)
    ea = edges === automatic ? () : (edges,)
    n = length(args)
    nw = args[n] isa StatsBase.AbstractWeights ? n : n+1
    ha, wa = args[1:(nw-1)], args[nw:n]
    length(ha) == 1 && (ha = ha[1])
    fit(StatsBase.Histogram, ha, wa..., ea...; kwargs...)
end

histogram(; kwargs...) = (args...) -> histogram(args...; kwargs...)
