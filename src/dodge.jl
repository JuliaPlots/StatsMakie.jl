@enum BarPosition superimpose dodge stack

used_attributes(P::PlotFunc, p::BarPosition, args...) =
    Tuple(union((:width, :space), used_attributes(P, args...)))

function convert_arguments(P::PlotFunc, p::BarPosition, args...;
    width = automatic, space = 0.2, kwargs...)
    plotspec = to_plotspec(P, convert_arguments(P, args...; kwargs...))
    ptype = plottype(plotspec)
    new_args, new_kwargs = plotspec.args, plotspec.kwargs
    @assert typeof(new_args) != typeof(args)
    final_plotspec = convert_arguments(ptype, p, new_args...;
        width = width, space = space)
    to_plotspec(ptype, final_plotspec; new_kwargs...)
end

function adjust_to_x(x, x′, y′)
    d = Dict(zip(x′, y′))
    [get(d, el, NaN) for el in x]
end

series2matrix(x, xs, ys) = hcat((adjust_to_x(x, x′, y′) for (x′, y′) in zip(xs, ys))...)

function convert_arguments(P::Type{<:MultiplePlot}, p::BarPosition, pl::PlotList; width = automatic, space = 0.2)
    xs_input = (ps[1] for ps in pl)
    ys_input = (ps[2] for ps in pl)
    n = length(pl)
    ft = automatic
    if p === superimpose
        w = width
        xs, ys = xs_input, ys_input
    else
        x = vcat(xs_input...)
        unique_x = union(sort(x))
        barwidth = width === automatic ? minimum(diff(unique_x))*(1-space) : width
        if p === dodge
            w = barwidth/n
            xs = (x .+ i*w .- w*(n+1)/2 for (i, x) in enumerate(xs_input))
            ys = ys_input
        else
            w = barwidth
            xs = xs_input
            y0, y1 = compute_stacked(series2matrix(x, xs_input, ys_input))
            y = y1 .- y0
            ft = y0
            ys = (adjust_to_x(x′, x, y[:, i]) for (i, x′) in enumerate(xs))
            fts = [adjust_to_x(x′, x, ft[:, i]) for (i, x′) in enumerate(xs)]
        end
    end
    plts = PlotSpec[]
    for (i, (x′, y′)) in enumerate(zip(xs, ys))
        fillto = ft === automatic ? automatic : fts[i]
        attr = Iterators.filter(p -> last(p) !== automatic, zip([:fillto, :width], [fillto, w]))
        push!(plts, PlotSpec{plottype(pl[i])}(x′, y′; attr..., pl[i].kwargs...))
    end

    PlotSpec{MultiplePlot}(PlotList(plts...))
end

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

    plts = PlotSpec[]
    for (i, (x′, y′)) in enumerate(zip(xs, ys))
        fillto = ft === automatic ? automatic : ft[:, i]
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
