convert_arguments(P::Type{<: AbstractPlot}, d::UnivariateKDE) =
    convert_arguments(P, d.x, d.density)
convert_arguments(P::Type{<: AbstractPlot}, d::BivariateKDE) =
    convert_arguments(P, d.x, d.y, d.density)

plottype(::UnivariateKDE) = Lines
plottype(::BivariateKDE) = Heatmap
