function validate_orientation(orientation)
    orientation = _maybe_unval(to_value(orientation))
    ishorizontal(orientation) && return
    isvertical(orientation) && return
    error("Invalid orientation $orientation. Valid options: :h, :hor, :horizontal, :v, :vert, :vertical.")
end

@inline function ishorizontal(orientation)
    return _maybe_unval(to_value(orientation)) ∈ (:horizontal, :h, :hor)
end

@inline function isvertical(orientation)
    return _maybe_unval(to_value(orientation)) ∈ (:vertical, :v, :vert)
end

_flip_xy(::Nothing) = nothing
_flip_xy(p::Point2f0) = reverse(p)
_flip_xy(r::Rect{2,T}) where {T} = Rect{2, T}(reverse(r.origin), reverse(r.widths))
_flip_xy(t::NTuple{2}) = reverse(t)
_flip_xy(r::Rect{N,T}) where {N,T} = _flip_xy(Rect{2,T}(r))
_flip_xy(v::AbstractVector) = reverse(v[1:2])

@inline _maybe_val(v::Val) = v
@inline _maybe_val(v) = Val(v)

@inline _maybe_unval(::Val{T}) where {T} = T
@inline _maybe_unval(v) = v

function _pixels_per_units(scene)
    limits = to_value(data_limits(scene))
    limits === nothing && return Vec2f0(0, 0)
    widthsdata = Vec2f0(widths(limits))
    widthsdatatot = widthsdata .* (1 .+ 2 .* Vec2f0(to_value(scene.padding)))
    widthspx = widths(to_value(pixelarea(scene)))
    return widthspx ./ widthsdatatot
end
