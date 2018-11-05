const default_scales = Dict(
    :color => AbstractPlotting.to_colormap(:Dark2),
    :marker => collect(keys(AbstractPlotting._marker_map)),
    :linestyle => [nothing, :dash, :dot, :dashdot, :dashdotdot],
)

isscale(::Function) = true
isscale(::AbstractArray) = true
isscale(::Any) = false
isscale(::Nothing) = false

function getscale(p::Combined, key)
    a = get(p, key, nothing)
    isscale(a[]) ? a : to_node(default_scales[key])
end