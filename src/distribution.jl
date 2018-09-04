# from StatPlots

@recipe(ScatterLines) do scene
    Theme()
end

function AbstractPlotting.plot!(scene::Scene, ::Type{ScatterLines}, attributes::Attributes, p...)
    plot!(scene, Scatter, attributes, p...)
    plot!(scene, Lines, attributes, p...)
    scene
end

# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1-alpha)
    minval, maxval
end

support(dist::Distribution) = default_range(dist)
support(dist::Distribution{<:VariateForm, <:Discrete}) = (UnitRange(default_range(dist)...),)

convert_arguments(P::Type{<:AbstractPlot}, dist::Distribution) = convert_arguments(P, dist, support(dist)...)
convert_arguments(P::Type{<:AbstractPlot}, dist::Distribution, args...) = convert_arguments(P, x -> pdf(dist, x), args...)
convert_arguments(P::Type{<:AbstractPlot}, f::Function, min, max) = convert_arguments(P, f, range(min, stop=max, length=100))
convert_arguments(P::Type{<:AbstractPlot}, f::Function, r) = convert_arguments(P, r, f.(r))

plottype(::Distribution) = Lines
plottype(::Distribution{<:VariateForm, <:Discrete}) = ScatterLines
#-----------------------------------------------------------------------------
# qqplots

# @recipe function f(h::QQPair; qqline = :identity)
#     if qqline in (:fit, :quantile, :identity, :R)
#         xs = [extrema(h.qx)...]
#         if qqline == :identity
#             ys = xs
#         elseif qqline == :fit
#             itc, slp = linreg(h.qx, h.qy)
#             ys = slp .* xs .+ itc
#         else # if qqline == :quantile || qqline == :R
#             quantx, quanty = quantile(h.qx, [0.25, 0.75]), quantile(h.qy, [0.25, 0.75])
#             slp = diff(quanty) ./ diff(quantx)
#             ys = quanty .+ slp .* (xs .- quantx)
#         end
#
#         @series begin
#             primary := false
#             seriestype := :path
#             xs, ys
#         end
#     end
#
#     seriestype --> :scatter
#     legend --> false
#     h.qx, h.qy
# end
#
# loc(D::Type{T}, x) where T<:Distribution = fit(D, x), x
# loc(D, x) = D, x
#
# @userplot QQPlot
# @recipe f(h::QQPlot) = qqbuild(loc(h.args[1], h.args[2])...)
#
# @userplot QQNorm
# @recipe f(h::QQNorm) = QQPlot((Normal, h.args[1]))
