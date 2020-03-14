using AlgebraOfGraphics: Product, Sum, traces, Trace, Analysis, AlgebraOfGraphics
import AlgebraOfGraphics: adjust_globally

# Heavy piracy, can we do better?
const PiratedTypes = Union{Type{<:AbstractPlot}, Attributes}

Base.:*(s::PiratedTypes, t::Any) = Product(s) * t
Base.:*(s::Any, t::PiratedTypes) = s * Product(t)
Base.:*(s::PiratedTypes, t::PiratedTypes) = Product(s, t)

Base.:*(t::Sum, b::PiratedTypes) = t * Product(b)
Base.:*(a::PiratedTypes, t::Sum) = a * Product(b)

Base.:+(s::PiratedTypes, t::Any) = Sum(s) + (t)
Base.:+(s::Any, t::PiratedTypes) = s + Sum(t)
Base.:+(s::PiratedTypes, t::PiratedTypes) = Sum(s, t)

# this will merge all attributes for a given product
AlgebraOfGraphics.combine(a::Attributes, b::Attributes) = merge(a, b)

# used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, f, args...)))

# used_attributes(P::PlotFunc, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, args...)))

function get_type(::Type{T}, metadata, default) where {T}
    i = findlast(x -> isa(x, T), metadata)
    i === nothing ? default : metadata[i]
end

function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, trace::Trace, metadata, rks)
    P = get_type(Type{<:AbstractPlot}, metadata, P)
    attr = merge(attr, get_type(Attributes, metadata, Attributes()))

    names = propertynames(trace.attributes)
    palette = AbstractPlotting.current_default_theme()[:palette]

    d = Dict{Symbol, Node}()
    for (key, val) in pairs(trace.attributes)
        user = get(attr, key, nothing)
        scale = user !== nothing && is_scale(user[]) ? user[] : palette[key][]
        attr[key] = compute_attribute(scale, val, rks[key])
    end
    plot!(scene, P, merge(attr, Attributes(trace.select.kwargs)), trace.select.args...)
    return scene
end

# TODO readd colorrange = automatic
# col = get(attributes, :color, nothing)
# if colorrange === automatic && col isa AbstractVector{<:Real}
#     colorrange = extrema_nan(col)
# end

function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, gs::Product)
    metadata, ts = traces(gs)
    rks = rankdicts([trace.attributes for trace in ts])
    for t in ts
        plot!(scene, P, attr, t, metadata, rks)
    end
    return scene
end

function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, gs::Sum)
    for el in gs.elements
        plot!(scene, P, attr, el)
    end
    return scene
end
