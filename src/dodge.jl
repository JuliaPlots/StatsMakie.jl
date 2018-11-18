@enum BarPosition superimpose dodge stack

used_attributes(P::PlotFunc, p::BarPosition, args...) = (:width, :position)

function convert_arguments(P::PlotFunc, p::BarPosition, x::AbstractVector, y::AbstractMatrix; width = automatic)
    n = size(y, 2)

    ft = automatic

    if p === superimpose
        w = width
        xs = (x for i in 1:n)
        ys = (y[:, i] for i in 1:n)
    else
        barwidth = width === automatic ? minimum(diff(unique(sort(x)))) : width
        if p === dodge
            w = 0.8*barwidth/n
            xs = (x .+ i*w .- w*(n+1)/2 for i in 1:n)
            ys = (y[:, i] for i in 1:n)
        else
            w = 0.8*barwidth
            xs = (x for i in 1:n)
            y0, y1 = compute_stacked(y)
            y = y1 .- y0
            ft = y0
            ys = (y[:, i] for i in 1:n)
        end
    end

    function adapt_theme(theme, i)
        fillto = ft === automatic ? automatic : fillto = ft[:, i]
        attr = Iterators.filter(p -> last(p) !== automatic, zip([:fillto, :width], [fillto, w]))
        new_theme = Theme(; attr...)
        merge(theme, new_theme)
    end

    convert_arguments(P, PlotList(collect(zip(xs, ys));
        transform_attributes = [theme -> adapt_theme(theme, i) for i in 1:n]))
end

function compute_stacked(y::AbstractMatrix)
    nr, nc = size(y)
    y1 = zeros(nr, nc)
    y0 = copy(y)
    y0[.!isfinite.(y0)] .= 0
    for r = 1:nr
        y_pos = y_neg = 0.0
        for c = 1:nc
            el = y0[r, c]
            if el >= 0
                y1[r, c] = y_pos
                y0[r, c] = y_pos += el
            else
                y1[r, c] = y_neg
                y0[r, c] = y_neg += el
            end
        end
    end
    y0, y1
end
