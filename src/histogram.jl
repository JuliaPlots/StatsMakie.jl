function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    convert_arguments(P, map(f, h.edges)..., h.weights)
end

plottype(::StatsBase.Histogram{<:Any, 1}) = BarPlot
plottype(::StatsBase.Histogram{<:Any, 2}) = Heatmap
plottype(::StatsBase.Histogram{<:Any, 3}) = Contour

@recipe(Histogram) do scene
    Theme(;
        default_theme(scene)...,
        closed = :right,
        nbins = nothing
    )
end

function plot!(plot::Histogram{<:NTuple{N}}) where N
    syms = [:closed, :nbins]
    fithist(args...; kwargs...) = fit(StatsBase.Histogram, args...; kwargs...)
    hist = lift_plot(fithist, plot; n = N, syms = syms)
    plot!(plot, Theme(plot), hist)
end
