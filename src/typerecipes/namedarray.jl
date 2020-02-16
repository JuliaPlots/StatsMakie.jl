const named_array_plot_types = [BarPlot, Heatmap, Volume]

struct NamedSparseArray{S<:Tuple, V<:AbstractVector}
    keys::S
    values::V
    function NamedSparseArray(args::AbstractVector...)
        keys = Base.front(args)
        values = last(args)
        return new{typeof(keys), typeof(values)}(keys, values)
    end
end

# this logic may be moved to AbstractPlotting
function dense(kv::NamedSparseArray)
    keys, values = kv.keys, kv.values
    labels = map(collect∘uniquesorted, keys)
    indices = map(Base.OneTo∘length, labels)
    converter = map((k, v) -> Dict(zip(k, v)), labels, indices)
    d = zeros(eltype(values), indices)
    for (k, v) in zip(StructArray(keys), values)
        I = map(getindex, converter, k)
        d[I...] = v
    end
    return labels, d
end

function convert_arguments(P::PlotFunc, m::NamedSparseArray)
    labels, values = dense(m)
    ptype = plottype(P, named_array_plot_types[length(labels)])
    to_plotspec(ptype, convert_arguments(ptype, labels..., values))
end

# TODO optimize with refarray and refvalue for pooled data
function _frequency(args...)
    s = StructArray(map(vec, args))
    gp = GroupPerm(s)
    sp = sortperm(gp)
    itr = (s[sp[first(range)]] => length(range) for range in gp)
    keys, values = fieldarrays(StructArray(itr, unwrap = t -> t <: Tuple))
    return NamedSparseArray(fieldarrays(keys)..., values)
end

const frequency = Analysis(_frequency)

