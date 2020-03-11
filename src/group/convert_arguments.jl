function convert_arguments(P::PlotFunc, f::Analysis, args...; kwargs...)
    tmp = f(args...; kwargs...) |> to_tuple
    convert_arguments(P, tmp...)
end

adjust_globally(s::Analysis, traces) = s

used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, f, args...)))

used_attributes(P::PlotFunc, g::GoG, args...) =
    Tuple(union((:colorrange,), used_attributes(P, args...)))

for typ in (:Function, :Analysis)
    @eval function convert_arguments(P::PlotFunc, f::($typ), arg::GoG, args...; kwargs...)
        convert_arguments(P, GrammarSpec((f, arg, args...)); kwargs...)
    end
end

convert_arguments(P::PlotFunc, arg::GoG, args...; kwargs...) =
    convert_arguments(P, tuple, arg, args...; kwargs...)

function to_plotspec(P::PlotFunc, g::TraceSpec, rks; kwargs...)
    plotspec = to_plotspec(P, convert_arguments(P, g.output...))
    names = propertynames(g.primary)
    d = Dict{Symbol, Node}()
    for (ind, key) in enumerate(names)
        f = function (user; palette = theme_scale)
            scale = is_scale(user) ? user : palette
            val = getproperty(g.primary, key)
            compute_attribute(scale, val, rks[ind])
        end
        d[key] = DelayedAttribute(f)
    end
    for (key, val) in node_pairs(kwargs)
        if !(key in names)
            d[key] = lift(t -> view(t, g.idxs), val)
        end
    end
    to_plotspec(P, plotspec; d...)
end

function convert_arguments(P::PlotFunc, gs::GrammarSpec; colorrange = automatic, kwargs...)
    traces, attributes = traces_attributes(gs)
    rks = rankdicts([trace.primary for trace in traces])
    series = (to_plotspec(P, trace, rks; attributes...) for trace in traces)
    pl = PlotList(series...)

    col = get(attributes, :color, nothing)
    if colorrange === automatic && col isa AbstractVector{<:Real}
        colorrange = extrema_nan(col)
    end

    PlotSpec{MultiplePlot}(pl, colorrange = colorrange)
end

struct DelayedAttribute
    f::Function
end

combine(theme_val, d::DelayedAttribute; palette = nothing, kwargs...) = d.f(theme_val; palette = palette)
