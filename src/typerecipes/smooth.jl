struct GLMResult{S, T}
    x::AbstractVector{S}
    y::AbstractVector{T}
    l::AbstractVector{T}
    u::AbstractVector{T}
end

function linear(x::AbstractVector{T1}, y::AbstractVector{T2}; n_points = 100) where {T1, T2}
    try
        lin_model = GLM.lm(@formula(Y ~ X), (X=x, Y=y))
        x_min, x_max = extrema(x)
        x_new = range(x_min, x_max, length = n_points)
        y_new, lower, upper = GLM.predict(lin_model,
         [ones(T1, n_points) x_new], interval=:confidence)
        # the GLM predictions always return matrices
       return GLMResult(x_new, vec(y_new), vec(lower), vec(upper))
    catch e
        error("Linear fit not possible for the given data")
    end
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