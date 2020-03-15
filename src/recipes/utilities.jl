function combine_color_alpha(c, alpha)
    col = to_color(c)
    RGBAf0(col.r, col.g, col.b, col.alpha * alpha)
end
