@enum BarPosition superimpose dodge stack

used_attributes(P::PlotFunc, p::BarPosition, args...) = (:width, :position)

function convert_arguments(P::PlotFunc, p::BarPosition, x::AbstractArray, y::AbstractArray; width = automatic)
    barwidth = width === automatic ? minimum(diff(unique(sort(x)))) : width
    n = size(y, 2)
    w = 0.8*barwidth/n
    adapt(theme) = merge(theme, Theme(width = w))

    xs = (x .+ i*w .- w*(n+1)/2 for i in 1:n)
    ys = (y[:, i] for i in 1:n)

    convert_arguments(P, PlotList(collect(zip(xs, ys)); transform_attributes = adapt))
end
