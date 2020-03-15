using AlgebraOfGraphics: Product, Sum, Traces, Analysis, metadata, AlgebraOfGraphics

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

# used_attributes(P::PlotFunc, f::Function, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, f, args...)))

# used_attributes(P::PlotFunc, g::GoG, args...) =
#     Tuple(union((:colorrange,), used_attributes(P, args...)))

function get_plotfunc(metadata, init = Any)
    i = findlast(x -> isa(x, PlotFunc), metadata)
    i === nothing ? Any : metadata[i]
end
function get_attributes(metadata, init = Attributes())
    a = copy(init)
    for el in metadata
        isa(el, Attributes) && merge!(a, el)
    end
    return a
end

# TODO readd colorrange = automatic
# col = get(attributes, :color, nothing)
# if colorrange === automatic && col isa AbstractVector{<:Real}
#     colorrange = extrema_nan(col)
# end

function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, ts::Traces)
    plot!(scene, P, attr, Product(ts))
end

# How to split so that it's overloadable?
function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, gs::Product)
    traces = Traces(gs)
    m = metadata(gs)
    P = get_plotfunc(m, P)
    attr = get_attributes(m, attr)
    rks = rankdicts(map(first, traces))
    palette = AbstractPlotting.current_default_theme()[:palette]
    for (trace_attr, select) in traces
        attr′ = copy(attr)
        d = Dict{Symbol, Node}()
        for (key, val) in pairs(trace_attr)
            user = get(attr, key, nothing)
            scale = user !== nothing && is_scale(user[]) ? user[] : palette[key][]
            attr′[key] = compute_attribute(scale, val, rks[key])
        end
        for (key, val) in pairs(select.kwargs)
            attr′[key] = val
        end
        plot!(scene, P, attr′, select.args...)
    end
    return scene
end

function plot!(scene::SceneLike, P::PlotFunc, attr::Attributes, gs::Sum)
    for el in gs.elements
        plot!(scene, P, attr, el)
    end
    return scene
end
