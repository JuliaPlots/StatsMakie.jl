@recipe(GroupedBar) do scene
    Theme(;
        default_theme(scene, BarPlot)...
    )
end

function plot!(p::GroupedBar)
    x, y = p[1:2]
    attr = copy(Theme(p))
    mb = get(p, :width, Node(nothing))
    barwidth = mb[] === nothing ? lift(minimum∘diff, x) : mb
    n = size(y[], 2)
    w = lift(t -> 0.8*t/n, barwidth)
    attr[:width] = w
    ys = (lift(t -> t[:, i], y) for i in 1:n)

    xs = (lift((t, u) -> t .+ i*u .- u*(n+1)/2, x, w) for i in 1:n)

    for (x′, y′) in zip(xs, ys)
        plot!(p, BarPlot, attr, x′, y′)
    end
end
