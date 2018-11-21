@enum BarPosition superimpose dodge stack

used_attributes(P::PlotFunc, p::BarPosition, args...) = (:width, :space)

convert_arguments(P::PlotFunc, p::BarPosition, y::AbstractMatrix; kwargs...) =
    convert_arguments(P, p, 1:size(y, 1), y; kwargs...)

function convert_arguments(P::PlotFunc, p::BarPosition, x::AbstractVector, y::AbstractMatrix;
    width = automatic, space = 0.2)

    n = size(y, 2)

    ft = automatic

    if p === superimpose
        w = width
        xs = (x for i in 1:n)
        ys = (y[:, i] for i in 1:n)
    else
        barwidth = width === automatic ? minimum(diff(unique(sort(x))))*(1-space) : width
        if p === dodge
            w = barwidth/n
            xs = (x .+ i*w .- w*(n+1)/2 for i in 1:n)
            ys = (y[:, i] for i in 1:n)
        else
            w = barwidth
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

    plts = PlotSpec[]
    for (i, (x′, y′)) in enumerate(zip(xs, ys))
        fillto = ft === automatic ? automatic : fillto = ft[:, i]
        attr = Iterators.filter(p -> last(p) !== automatic, zip([:fillto, :width], [fillto, w]))
        push!(plts, PlotSpec(x′, y′; attr...))
    end

    convert_arguments(P, PlotList(plts...))
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
