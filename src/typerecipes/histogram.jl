export histogram

const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

to_weights(v) = StatsBase.weights(v)
to_weights(v::StatsBase.AbstractWeights) = v

bool2options(t::Bool, a, b) = t ? a : b
bool2options(t, a, b) = t

function _histogram(args...; edges = automatic, weights = automatic, normalize = false, kwargs...)
    ea = edges === automatic ? () : (to_tuple(edges),)
    wa = weights === automatic ? () : (to_weights(weights),)
    ha = length(args) == 1 ? args[1] : args
    attr = Dict(kwargs)
    isempty(ea) || pop!(attr, :nbins, nothing)
    h = fit(StatsBase.Histogram, to_tuple(ha), wa..., ea...; attr...)
    norm_option = bool2options(normalize, :pdf, :none)
    StatsBase.normalize(h, mode = norm_option)
end

const histogram = Analysis(_histogram)

function adjust_globally(hist::Analysis{typeof(_histogram)}, traces)
    (length(traces) == 1 || get(hist.kwargs, :edges, automatic) !== automatic) && return hist
    global_output = map(concatenate, (trace.output for trace in traces)...)
    h = hist(global_output...)
    Analysis(hist.f; merge(hist.kwargs, (edges = h.edges,))...)
end
