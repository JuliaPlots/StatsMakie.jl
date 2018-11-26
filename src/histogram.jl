export histogram

const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

function  histogram(args...; edges = automatic, weights = automatic, kwargs...)
    attr = Dict{Symbol, Any}()
    edges !== automatic && (attr[:edges] = edges)
    weights !== automatic && (attr[:weights] = StatsBase.weights(weights))
    ha = length(args) > 1 ? args : args[1]
    fit(StatsBase.Histogram, ha; attr..., kwargs...)
end

histogram(; kwargs...) = (args...) -> histogram(args...; kwargs...)
