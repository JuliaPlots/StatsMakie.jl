export histogram

const histogram_plot_types = [BarPlot, Heatmap, Contour]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    histogram_plot_types[N] => convert_arguments(P, map(f, h.edges)..., h.weights)
end

histogram(args...; kwargs...) = fit(Histogram, args...; kwargs...)
histogram(; kwargs...) = (args...) -> histogram(args...; kwargs...)

used_attributes(::PlotFunc, ::typeof(histogram), args...) = (:closed, :nbins)
