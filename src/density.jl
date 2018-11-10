function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    ptype => convert_arguments(ptype, d.x, d.density)
end

function convert_arguments(P::Type{<: Combined{T}}, d::KernelDensity.BivariateKDE) where T
    ptype = plottype(P, Heatmap)
    ptype => convert_arguments(ptype, d.x, d.y, d.density)
end

used_attributes(::PlotFunc, ::typeof(kde), args...) = (:bandwidth, :kernel, :npoints, :boundary, :weights)
