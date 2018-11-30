abstract type AbstractAnalysis{T} end

struct Analysis{T, N<:NamedTuple} <: AbstractAnalysis{T}
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
(an::Analysis)(args...; kwargs...) = apply_keywords(an.f, args...; kwargs..., an.kwargs...)

function convert_arguments(P::PlotFunc, f::AbstractAnalysis, args...; kwargs...)
    tmp = f(args...; kwargs...) |> to_tuple
    convert_arguments(P, tmp...)
end

const FunctionOrAnalysis = Union{Function, AbstractAnalysis}

adjust_globally(s::FunctionOrAnalysis, traces) = s
