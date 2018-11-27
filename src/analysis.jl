abstract type AbstractAnalysis{T} end

struct Analysis{T} <: AbstractAnalysis{T}
    f::T
    kwargs::Dict{Symbol, Any}
    Analysis(f::T; kwargs...) where {T} = new{T}(f, Dict{Symbol, Any}(kwargs))
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
(an::Analysis)(args...; kwargs...) = apply_keywords(an.f, args...; kwargs..., an.kwargs...)

function convert_arguments(P::PlotFunc, f::AbstractAnalysis, args...; kwargs...)
    tmp = f(args...; kwargs...) |> to_tuple
    convert_arguments(P, tmp...)
end

const FunctionOrAnalysis = Union{Function, AbstractAnalysis}
