function combine_color_alpha(c, alpha)
    col = to_color(c)
    RGBAf0(col.r, col.g, col.b, col.alpha * alpha)
end

"""
    ribbon(x, y, yerror)

Plots a filled area centered along the line specified
by `x` and `y`, with thickness specified by `error`.
"""
@recipe(Ribbon) do scene
    Theme(;
        default_theme(scene, Band)...,
        color = theme(scene, :color),
        fillalpha = 0.2
    )
end

_get(t::Tuple, i) = t[i]
_get(t, i) = t

function _get_broadcast(y, t, i)
    v = _get(t, i)
    err = v isa AbstractVector ? _get.(v, i) : fill!(similar(y), v)
    y .+ (-1)^i .* err
end

function plot!(p::Ribbon)
    x, y = p[1:2]
    yerr = p[3]
    ylow = lift(_get_broadcast, y, yerr, Node(1))
    yhigh = lift(_get_broadcast, y, yerr, Node(2))

    theme = copy(Theme(p))
    theme[:color] = lift(combine_color_alpha, Theme(p)[:color], Theme(p)[:fillalpha])
    plot!(p, Band, theme, x, ylow, yhigh)
end
