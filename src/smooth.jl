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
