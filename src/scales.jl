to_scale(x::Function) = x
to_scale(x::AbstractArray) = x
to_scale(x::Any) = nothing
to_scale(x::Nothing) = nothing
