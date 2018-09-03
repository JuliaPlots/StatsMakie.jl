argument_convert(d::UnivariateKDE) = (d.x, d.density)
argument_convert(d::BivariateKDE) = (d.x, d.y, d.density)

plottype(::BivariateKDE) = Heatmap
