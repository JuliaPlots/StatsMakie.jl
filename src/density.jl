_to_values(d::UnivariateKDE) = (d.x, d.density)
_to_values(d::BivariateKDE) = (d.x, d.y, d.density)

convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.AbstractKDE) =
    convert_arguments(P, _to_values(d)...)

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
    _args = lift(_to_values, h)
    args = Tuple(lift(t->t[i], _args) for i in 1:length(to_value(_args)))
    plot!(scene, plottype(to_value(h)), attr, args...)
    scene
end
