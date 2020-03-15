"""
    shaded_line(x, y, `lower`, `upper`)

Plots a line through `x` and `y` and a filled area
behind it defined by `lower` and `upper`
"""
@recipe(ShadedLine, x, y, lower, upper) do scene
    Theme(;
        default_theme(scene, Band)...,
        color = theme(scene, :color),
        fillalpha = 0.2
    )
end

function plot!(p::ShadedLine)
    x, y, lower, upper = p[1:4]
    theme = copy(Theme(p))
    theme[:color] = lift(combine_color_alpha, Theme(p)[:color], Theme(p)[:fillalpha])
    plot!(p, Band, theme, x, lower, upper)
    plot!(p, Lines, Theme(p), x, y)
end
