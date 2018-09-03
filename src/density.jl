convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.UnivariateKDE) =
    convert_arguments(P, d.x, d.density)

convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.BivariateKDE) =
    convert_arguments(P, d.x, d.y, d.density)

plottype(::UnivariateKDE) = Lines
plottype(::BivariateKDE) = Heatmap

@recipe(Density) do scene
    Theme()
end

function AbstractPlotting.plot!(scene::Scene, ::Type{Density}, attributes::Attributes, p...)
    attr = copy(attributes)
    hist_kwarg = [:boundary, :npoints, :kernel, :bandwidth]
    hist_attr = [pop!(attr, key, Signal(nothing)) for key in hist_kwarg]
    h = lift(hist_attr...) do v...
        kwargs = (t for t in zip(hist_kwarg, v) if last(t) !== nothing)
        kde(p...; kwargs...)
    end
    plot!(scene, attr, h)
    scene
end
