const default_scales = Dict(
    :color => AbstractPlotting.to_colormap(:Dark2, 8),
    :marker => [:circle, :xcross, :utriangle, :diamond, :dtriangle, :star6, :pentagon, :rect],
    :linestyle => [nothing, :dash, :dot, :dashdot, :dashdotdot],
    :side => [:left, :right]
)

isscale(::Function) = true
isscale(::AbstractArray) = true
isscale(::Any) = false
isscale(::Nothing) = false

function getscale(p::Theme, key)
    a = get(p, key, Node(nothing))
    isscale(a[]) ? a : to_node(default_scales[key])
end
