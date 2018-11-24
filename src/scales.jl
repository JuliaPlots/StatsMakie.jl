const default_scales = Dict(
    :color => ["#9b3950", "#f79b57", "#6b3241", "#e65e62", "#9e7587", "#4C8659", "#6B6C69", "#0b0e0a"],
    :marker => [:circle, :xcross, :utriangle, :diamond, :dtriangle, :star6, :pentagon, :rect],
    :linestyle => [nothing, :dash, :dot, :dashdot, :dashdotdot],
    :side => [:left, :right]
)

to_scale(x::Function) = x
to_scale(x::AbstractArray) = x
to_scale(x::Any) = nothing
to_scale(x::Nothing) = nothing
