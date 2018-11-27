export density

function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(P::PlotFunc, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

function trim_limits!(x, lims)
    len = column_length(x)
    for i in 1:width(x)
        xmin, xmax = extrema_nan(extract_view(x, 1:len, i))
        xmin′, xmax′ = lims[i]
        lims[i] = (max(xmin′, xmin), min(xmax′, xmax))
    end
end

function search_both(x, xlims)
    min, max = xlims
    x1 = searchsortedfirst(x, min)
    x2 = searchsortedlast(x, max)
    (x1, x2)
end

function trim_density(k::UnivariateKDE, lims::AbstractVector{<:Tuple})
    x1, x2 = search_both(k.x, lims[1])
    UnivariateKDE(k.x[x1:x2], k.density[x1:x2])
end

function trim_density(k::BivariateKDE, lims::AbstractVector{<:Tuple})
    x1, x2 = search_both(k.x, lims[1])
    y1, y2 = search_both(k.y, lims[2])
    BivariateKDE(k.x[x1:x2], k.y[y1:y2], k.density[x1:x2, y1:y2])
end

function trim_density(k::KernelDensity.AbstractKDE, x; xlims = (-Inf, Inf), ylims = (-Inf, Inf), trim = false)
    lims = Tuple[extrema(xlims), extrema(ylims)]
    trim && trim_limits!(x, lims)
    trim_density(k, lims)
end

function _density(x; xlims = (-Inf, Inf), ylims = (-Inf, Inf), trim = false, kwargs...)
    k = kde(x; kwargs...)
    trim_density(k, x; xlims = xlims, ylims = ylims, trim = trim)
end

function _density(x, y; xlims = (-Inf, Inf), ylims = (-Inf, Inf), trim = false, kwargs...)
    k = kde((x, y); kwargs...)
    trim_density(k, (x, y); xlims = xlims, ylims = ylims, trim = trim)
end

const density = Analysis(_density)
