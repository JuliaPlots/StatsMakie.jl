convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.UnivariateKDE) =
    convert_arguments(P, d.x, d.density)

convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.BivariateKDE) =
    convert_arguments(P, d.x, d.y, d.density)

plottype(::UnivariateKDE) = Lines
plottype(::BivariateKDE) = Heatmap

@recipe(Density) do scene
    Theme()
end

function plot!(scene::SceneLike, ::Type{<:Density}, attributes::Attributes, p...)
    kde_attr, attr = splitattributes(attributes, [:boundary, :npoints, :kernel, :bandwidth])
    h = LiftedKwargs(kde_attr)(kde, p...)
    plot!(scene, attr, h)
    scene
end
