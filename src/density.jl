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

function plot!(plot::Density{<:NTuple{N}}) where N
    pdf = lift_plot(kde, plot; n = N, syms = [:boundary, :npoints, :kernel, :bandwidth])
    plot!(plot, Theme(plot), pdf)
end
