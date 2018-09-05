splitattributes(attributes::Attributes, v::AbstractArray{Symbol}) = splitattributes!(copy(attributes), v)

function splitattributes!(attr::Attributes, v::AbstractArray{Symbol})
    kw = Dict{Symbol, Signal}()
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

function (kw::LiftedKwargs)(f, args...; kwargs...)
    lift(values(kw)...) do v...
        f(args...; kwargs..., zip(keys(kw), v)...)
    end
end
