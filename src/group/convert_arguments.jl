using AlgebraOfGraphics: Product, Sum, traces, Trace, Analysis
import AlgebraOfGraphics: adjust_globally

# Heavy piracy, can we do better?
Base.:*(s::Type{<:AbstractPlot}, t::Any) = Product(s) * t
Base.:*(s::Any, t::Type{<:AbstractPlot}) = s * Product(t)
Base.:*(s::Type{<:AbstractPlot}, t::Type{<:AbstractPlot}) = Product(s, t)

Base.:*(t::Sum, b::Type{<:AbstractPlot}) = t * Product(b)
Base.:*(a::Type{<:AbstractPlot}, t::Sum) = a * Product(b)

Base.:+(s::Type{<:AbstractPlot}, t::Any) = Sum(s) + (t)
Base.:+(s::Any, t::Type{<:AbstractPlot}) = s + Sum(t)
Base.:+(s::Type{<:AbstractPlot}, t::Type{<:AbstractPlot}) = Sum(s, t)

# used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, f, args...)))

# used_attributes(P::PlotFunc, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, args...)))

function to_plotspec(P::PlotFunc, g::Trace, rks)
    new_args = convert_arguments(P, g.select.args...; g.select.kwargs...)
    plotspec = to_plotspec(P, new_args)
    names = propertynames(g.attributes)
    d = Dict{Symbol, Node}()
    for (ind, key) in enumerate(names)
        f = function (user; palette = theme_scale)
            scale = is_scale(user) ? user : palette
            val = getproperty(g.attributes, key)
            compute_attribute(scale, val, rks[ind])
        end
        d[key] = DelayedAttribute(f)
    end
    for (key, val) in node_pairs(g.select.kwargs)
        if !(key in names)
            d[key] = lift(t -> view(t, g.idxs), val)
        end
    end
    to_plotspec(P, plotspec; d...)
end

function _convert_arguments(P::PlotFunc, gs::Product; kwargs...)
                           # TODO readd colorrange = automatic
    metadata, ts = traces(gs)
    i = findlast(x -> isa(x, Type{<:AbstractPlot}), metadata)
    if i !== nothing
        P = plottype(P, metadata[i])
    end
    rks = rankdicts([trace.attributes for trace in ts])
    series = [to_plotspec(P, trace, rks) for trace in ts]
end

function convert_arguments(P::PlotFunc, gs::Product; kwargs...)
    series = _convert_arguments(P, gs; kwargs...)
    pl = PlotList(series...)

    # col = get(attributes, :color, nothing)
    # if colorrange === automatic && col isa AbstractVector{<:Real}
    #     colorrange = extrema_nan(col)
    # end

    PlotSpec{MultiplePlot}(pl) #, colorrange = colorrange)
end

function convert_arguments(P::PlotFunc, gs::Sum; kwargs...)
    nested_series = [_convert_arguments(P, el; kwargs...) for el in gs.elements]
    series = reduce(vcat, nested_series)
    pl = PlotList(series...)
    PlotSpec{MultiplePlot}(pl) #, colorrange = colorrange)
end

struct DelayedAttribute
    f::Function
end

combine(theme_val, d::DelayedAttribute; palette = nothing, kwargs...) = d.f(theme_val; palette = palette)
