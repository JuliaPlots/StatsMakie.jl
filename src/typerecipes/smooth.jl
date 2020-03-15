struct GLMResult{S, T}
    x::AbstractVector{S}
    y::AbstractVector{T}
    l::AbstractVector{T}
    u::AbstractVector{T}
end

function linear(x::AbstractVector{T}, y::AbstractVector{T}) where {T}
    lin_model = GLM.lm(@formula(Y ~ X), (X=x, Y=y))
    y_new, lower, upper = GLM.predict(lin_model,
     [ones(T, length(x)) x], interval=:confidence)
    # the GLM predictions always return matrices
   return GLMResult(x, vec(y_new), vec(lower), vec(upper))
end

convert_arguments(P::PlotFunc, g::GLMResult) = PlotSpec{ShadedLine}(g.x, g.y, g.l, g.u)

struct Smooth{S, T}
    x::Vector{S}
    y::Vector{T}
end

convert_arguments(P::PlotFunc, l::Smooth) = PlotSpec{Lines}(Point2f0.(l.x,l.y))

function smooth(x, y; length = 100, kwargs...)
    model = loess(x, y; kwargs...)
    min, max = extrema(x)
    us = collect(range(min, stop = max, length = length))
    vs = predict(model, us)
    Smooth(us, vs)
end

smooth(; kwargs...) = (args...) -> smooth(args...; kwargs...)
