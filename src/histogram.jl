function hist2values(h::StatsBase.Histogram)
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    (map(f, h.edges)..., h.weights)
end

convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram) =
    convert_arguments(P, hist2values(h)...)

plottype(::StatsBase.Histogram{<:Any, 1}) = BarPlot
plottype(::StatsBase.Histogram{<:Any, 2}) = Heatmap

@recipe(Histogram) do scene
    Theme(;
        default_theme(scene)...,
        nbins = nothing,
        closed = :default_left
    )
end

# From the StatPlots examples in Makie

function AbstractPlotting.plot!(p::Histogram)
    # we assume that the y kwarg is set with the data to be binned, and nbins is also defined
    l = length(p.converted)
    h = lift(p[1:l]..., p[:nbins], p[:closed]) do v...
        args, nbins, closed =  v[1:end-2], v[end-1], v[end]
        kwargs = (nbins = nbins, closed = closed)
        fit(StatsBase.Histogram, args...; Iterators.filter(t -> last(t) !== nothing, pairs(kwargs))...)
    end
    _args = lift(hist2values, h)
    args = Tuple(lift(t->t[i], _args) for i in 1:length(to_value(_args)))
    t = copy(theme(p))
    for (key, val) in t
        t[key] = get(p, key, val)
    end
    plot!(plottype(to_value(h)), t, args...)
end
