splitattributes(attributes::Attributes, v::AbstractArray{Symbol}) = splitattributes!(copy(attributes), v)

function splitattributes!(attr::Attributes, v::AbstractArray{Symbol})
    kw = Dict{Symbol, Observable}()
    for key in v
        val = pop!(attr, key, nothing)
        val !== nothing && (kw[key] = val)
    end
    kw, attr
end

struct LiftedKwargs{T}
    d::T
end

Base.keys(kw::LiftedKwargs) = keys(kw.d)
Base.values(kw::LiftedKwargs) = values(kw.d)
Base.iterate(kw::LiftedKwargs, args...) = iterate(kw.d, args...)

_lift(f) = f()
_lift(f, args...) = lift(f, args...)

function (kw::LiftedKwargs)(f, args...; kwargs...)
    _lift(values(kw)...) do v...
        f(args...; kwargs..., zip(keys(kw), v)...)
    end
end
