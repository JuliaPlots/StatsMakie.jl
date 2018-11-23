struct Linear{S, T}
    x::NTuple{2, S}
    y::NTuple{2, T}
end

convert_arguments(P::PlotFunc, l::Linear) = PlotSpec{LineSegments}([Point2f0(x,y) for (x,y) in zip(l.x, l.y)])

function linear(x, y)
    itc, slp = hcat(fill!(similar(x), 1), x) \ y
    xs = extrema_nan(x)
    ys = slp .* xs .+ itc
    Linear(xs, ys)
end

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
