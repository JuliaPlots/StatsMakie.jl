export histogram

const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : (;)
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

histogram(args...; kwargs...) = fit(StatsBase.Histogram, args...; kwargs...)
histogram(; kwargs...) = (args...) -> histogram(args...; kwargs...)

used_attributes(::PlotFunc, ::typeof(histogram), args...) = (:closed, :nbins)
