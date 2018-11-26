export density

function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(P::PlotFunc, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

density(x; kwargs...) = kde(x; kwargs...)
density(x, w::StatsBase.AbstractWeights; kwargs...) = kde(x; weights = w, kwargs...)
density(x, y; kwargs...) = kde((x, y); kwargs...)
density(x, y, w::StatsBase.AbstractWeights; kwargs...) = kde((x, y); weights = w, kwargs...)
density(; kwargs...) = (args...) -> density(args...; kwargs...)
