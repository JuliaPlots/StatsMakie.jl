const named_array_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::PlotFunc, m::NamedArray)
    n = length(axes(m))
    ptype = plottype(P, named_array_plot_types[n])
    args = (names(m, i) for i in 1:n)
    v = convert(Array, m)
    to_plotspec(ptype, convert_arguments(ptype, args..., v))
end

const frequency = Analysis(freqtable)
