convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.UnivariateKDE) =
    convert_arguments(P, d.x, d.density)

convert_arguments(P::Type{<: AbstractPlot}, d::KernelDensity.BivariateKDE) =
    convert_arguments(P, d.x, d.y, d.density)

plottype(::UnivariateKDE) = Lines
plottype(::BivariateKDE) = Heatmap

@recipe(Density) do scene
    Theme(;
        default_theme(scene)...,
        boundary = nothing,
        npoints = nothing,
        kernel = nothing,
        bandwidth = nothing
    )
end

function default_theme(scene, ::Type{<:Density{<:Tuple{P, Vararg}}}) where {P}
    Theme(;
        default_theme(scene, P)...,
        boundary = nothing,
        npoints = nothing,
        kernel = nothing,
        bandwidth = nothing
    )
end

_plottype(::Type{<:Density}, arg::AbstractArray{<:Any, 1}, args...) = Lines 
_plottype(::Type{<:Density}, args...) = Heatmap 

convert_arguments(::Type{<:Density}, P::Type{<:AbstractPlot}, args...) = (P, args...)
convert_arguments(::Type{T}, args...) where {T<:Density} =
    convert_arguments(T, _plottype(T, args...)::Type{<:AbstractPlot}, args...)

function plot!(plot::Density{<:Tuple{Vararg{Any, N}}}) where N
    pdf = lift_plot(kde, plot; range = 2:N, syms = [:boundary, :npoints, :kernel, :bandwidth])
    plot!(plot, plot[1][], Theme(plot), pdf)
end
