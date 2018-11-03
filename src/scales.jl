const default_scales = Dict(
    :color => AbstractPlotting.to_colormap(:Dark2),
    :marker => collect(keys(AbstractPlotting._marker_map)),
    :linestyle => [nothing, :dash, :dot, :dashdot, :dashdotdot],
)
