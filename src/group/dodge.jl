module Position
    @enum Arrangement superimpose dodge stack
end

used_attributes(P::PlotFunc, p::Position.Arrangement, args...) =
    Tuple(union((:width, :space), used_attributes(P, args...)))

function convert_arguments(P::PlotFunc, p::Position.Arrangement, args...;
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
    x === x′ && return y′
    d = Dict(zip(x′, y′))
    [get(d, el, NaN) for el in x]
end

series2matrix(x, xs, ys) = hcat((adjust_to_x(x, x′, y′) for (x′, y′) in zip(xs, ys))...)

extract_var(ps, i) =
    ps[1] isa AbstractArray{<:AbstractArray} ? getindex.(ps[1], i) : ps[i]

function convert_arguments(P::PlotFunc, p::Position.Arrangement, pl::PlotList; width = automatic, space = 0.2)
    xs_input = (extract_var(ps, 1) for ps in pl)
    ys_input = (extract_var(ps, 2) for ps in pl)
    fts = (automatic for ps in pl)
    n = length(pl)
    if p === Position.superimpose
        w = width
        xs, ys = xs_input, ys_input
    else
        x1 = first(xs_input)
        x = all(t -> t === x1, xs_input) ? x1 : vcat(xs_input...)
        unique_x = unique(sort(x))
        barwidth = width === automatic ? minimum(diff(unique_x))*(1-space) : width
        if p === Position.dodge
            w = barwidth/n
            xs = (x .+ i*w .- w*(n+1)/2 for (i, x) in enumerate(xs_input))
            ys = ys_input
        else
            w = barwidth
            xs = xs_input
            y_mat = series2matrix(x, xs_input, ys_input)
            y0, y1 = compute_stacked(y_mat; reverse = true)
            y = y1 .- y0
            ft = y0
            ys = (adjust_to_x(x′, x, y[:, i]) for (i, x′) in enumerate(xs))
            fts = (adjust_to_x(x′, x, ft[:, i]) for (i, x′) in enumerate(xs))
        end
    end
    plts = PlotSpec[]
    for (i, (x′, y′, ft)) in enumerate(zip(xs, ys, fts))
        attr = Iterators.filter(p -> last(p) !== automatic, zip([:fillto, :width], [ft, w]))
        push!(plts, PlotSpec{plottype(pl[i])}(x′, y′; attr..., pl[i].kwargs...))
    end

    PlotSpec{MultiplePlot}(PlotList(plts...))
end

convert_arguments(P::PlotFunc, p::Position.Arrangement, y::AbstractMatrix; kwargs...) =
    convert_arguments(P, p, 1:size(y, 1), y; kwargs...)

function convert_arguments(P::PlotFunc, p::Position.Arrangement, x::AbstractVector, y::AbstractMatrix;
    width = automatic, space = 0.2)

    n = size(y, 2)
    plots = PlotSpec[]
    for i in 1:n
        push!(plots, PlotSpec{P}(x, y[:, i]))
    end
    convert_arguments(MultiplePlot, p, PlotList(plots...); width = width, space = space)
end

function compute_stacked(y::AbstractMatrix; reverse = false)
    nr, nc = size(y)
    y1 = zeros(nr, nc)
    y0 = copy(y)
    y0[.!isfinite.(y0)] .= 0
    col_idxs = reverse ? (nc:-1:1) : (1:nc)
    for r = 1:nr
        y_pos = y_neg = 0.0
        for c = col_idxs
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
