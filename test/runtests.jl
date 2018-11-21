using Makie, StatsMakie, StatsBase
using Test

using Random: seed!
using GeometryTypes: HyperRectangle
using IndexedTables
using Distributions

seed!(0)

@testset "boxplot" begin
    a = repeat(1:5, inner = 20)
    b = 1:100
    p = boxplot(a, b)
    plts = p[end].plots
    @test length(plts) == 3
    @test plts[1] isa Scatter
    @test isempty(plts[1][1][])

    @test plts[2] isa LineSegments
    pts = Point{2, Float32}[
        [1.0, 5.75], [1.0, 1.0], [0.6, 1.0], [1.4, 1.0], [1.0, 15.25],
        [1.0, 20.0], [1.4, 20.0], [0.6, 20.0], [2.0, 25.75], [2.0, 21.0],
        [1.6, 21.0], [2.4, 21.0], [2.0, 35.25], [2.0, 40.0], [2.4, 40.0],
        [1.6, 40.0], [3.0, 45.75], [3.0, 41.0], [2.6, 41.0], [3.4, 41.0],
        [3.0, 55.25], [3.0, 60.0], [3.4, 60.0], [2.6, 60.0], [4.0, 65.75],
        [4.0, 61.0], [3.6, 61.0], [4.4, 61.0], [4.0, 75.25], [4.0, 80.0],
        [4.4, 80.0], [3.6, 80.0], [5.0, 85.75], [5.0, 81.0], [4.6, 81.0],
        [5.4, 81.0], [5.0, 95.25], [5.0, 100.0], [5.4, 100.0], [4.6, 100.0]
    ]
    @test plts[2][1][] == pts

    @test plts[3] isa Poly

    poly = HyperRectangle{2,Float32}[
        HyperRectangle{2,Float32}(Float32[0.6, 5.75], Float32[0.8, 4.75]),
        HyperRectangle{2,Float32}(Float32[0.6, 15.25], Float32[0.8, -4.75]),
        HyperRectangle{2,Float32}(Float32[1.6, 25.75], Float32[0.8, 4.75]),
        HyperRectangle{2,Float32}(Float32[1.6, 35.25], Float32[0.8, -4.75]),
        HyperRectangle{2,Float32}(Float32[2.6, 45.75], Float32[0.8, 4.75]),
        HyperRectangle{2,Float32}(Float32[2.6, 55.25], Float32[0.8, -4.75]),
        HyperRectangle{2,Float32}(Float32[3.6, 65.75], Float32[0.8, 4.75]),
        HyperRectangle{2,Float32}(Float32[3.6, 75.25], Float32[0.8, -4.75]),
        HyperRectangle{2,Float32}(Float32[4.6, 85.75], Float32[0.8, 4.75]),
        HyperRectangle{2,Float32}(Float32[4.6, 95.25], Float32[0.8, -4.75])
    ]

    @test plts[3][1][] == poly
end

@testset "density" begin
    v = randn(1000)
    d = density(v, bandwidth = 0.1)
    p1 = plot(d)
    p2 = lines(d.x, d.density)
    @test p1[end][1][] == p2[end][1][]
    p3 = plot(density, v, bandwidth = 0.1)
    @test p3[end] isa Lines
    @test p3[end][1][] == p1[end][1][]
    x = randn(1000)
    y = randn(1000)
    v = (x, y)
    d = density(v, bandwidth = (0.1, 0.1))
    p1 = heatmap(d)
    p2 = heatmap(d.x, d.y, d.density)
    @test p1[end][1][] == p2[end][1][]
    p3 = plot(density(bandwidth = (0.1, 0.1)), v)
    @test p3[end] isa Heatmap
    @test p3[end][1][] == p1[end][1][]
    p4 = surface(density(bandwidth = (0.1, 0.1)), v))
    @test p4[end] isa Surface
    @test p4[end][1][] == p1[end][1][]

    t = table((x = x, y = y))
    p5 = surface(density(bandwidth = (0.1, 0.1)), Data(t), (:x, :y))
    plt = p5[end].plots[1]
    @test plt isa Surface
    @test plt[1][] == p1[end][1][]

    p6 = surface(density(bandwidth = (0.1, 0.1)), Data(t), [:x :y])
    plt = p6[end].plots[1]
    @test plt isa Surface
    @test plt[1][] == p1[end][1][]
end

@testset "distribution" begin
    d = Normal()
    p = plot(d)
    plt = p[end]
    @test plt isa Lines
    @test !StatsMakie.isdiscrete(d)
    @test first(plt[1][][1]) ≈ -3.6826972435271177 rtol = 1e-6
    @test first(plt[1][][end]) ≈ 3.6717509992155426 rtol = 1e-6
    @test last.(plt[1][]) ≈ pdf.(d, first.(plt[1][])) rtol = 1e-6

    d = Poisson()
    p = plot(d)
    @test p[end] isa ScatterLines
    plt = p[end].plots[1]
    @test StatsMakie.isdiscrete(d)

    @test first.(plt[1][]) == 0:6
    @test last.(plt[1][]) ≈ pdf.(d, first.(plt[1][]))
end

@testset "group" begin
    c = repeat(1:2, inner = 50)
    m = repeat(1:2, outer = 50)
    p = scatter(
        Group(
            color = c,
            marker = m,
        ),
        1:100,
        1:100,
        color = [:blue, :red],
        marker = [:cross, :circle]
    )
    @test length(p[end].plots) == 4
    @test p[end].plots[1].color[] == :blue
    @test p[end].plots[2].color[] == :blue
    @test p[end].plots[3].color[] == :red
    @test p[end].plots[4].color[] == :red
    @test p[end].plots[1].marker[] == :cross
    @test p[end].plots[2].marker[] == :circle
    @test p[end].plots[3].marker[] == :cross
    @test p[end].plots[4].marker[] == :circle

    @test p[end].plots[1][1][] == Point{2, Float32}.(1:2:49, 1:2:49)
    @test p[end].plots[2][1][] == Point{2, Float32}.(2:2:50, 2:2:50)
    @test p[end].plots[3][1][] == Point{2, Float32}.(51:2:99, 51:2:99)
    @test p[end].plots[4][1][] == Point{2, Float32}.(52:2:100, 52:2:100)

    t = table((x = 1:100, y = 1:100, m = m, c = c))
    q = scatter(
        Data(t),
        Group(color = :c, marker = :m),
        :x, :y,
        color = [:blue, :red],
        marker = [:cross, :circle]
    )

    @test length(q[end].plots) == 4
    @test q[end].plots[1].color[] == :blue
    @test q[end].plots[2].color[] == :blue
    @test q[end].plots[3].color[] == :red
    @test q[end].plots[4].color[] == :red
    @test q[end].plots[1].marker[] == :cross
    @test q[end].plots[2].marker[] == :circle
    @test q[end].plots[3].marker[] == :cross
    @test q[end].plots[4].marker[] == :circle

    @test q[end].plots[1][1][] == Point{2, Float32}.(1:2:49, 1:2:49)
    @test q[end].plots[2][1][] == Point{2, Float32}.(2:2:50, 2:2:50)
    @test q[end].plots[3][1][] == Point{2, Float32}.(51:2:99, 51:2:99)
    @test q[end].plots[4][1][] == Point{2, Float32}.(52:2:100, 52:2:100)
end

@testset "histogram" begin
    v = randn(1000)
    h = fit(Histogram, v)
    p = plot(h)

    plt = p[end]
    @test plt isa BarPlot
    x = h.edges[1]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] == h.weights

    v = (randn(1000), randn(1000))
    h = fit(Histogram, v, nbins = 30)
    p = plot(h)
    plt = p[end]
    @test plt isa Heatmap
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] == h.weights

    p = surface(h)
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] == h.weights

    p = surface(histogram, v, nbins = 30)
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] == h.weights

    v = (randn(1000), randn(1000), randn(1000))
    h = fit(Histogram, v)
    p = plot(h)
    plt = p[end]
    @test plt isa Volume
    x = h.edges[1]
    y = h.edges[2]
    z = h.edges[3]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ z[1:end-1] .+ step(z)/2
    @test plt[4][] == h.weights
end

@testset "qqplot" begin
    v = randn(1000)
    q = qqbuild(fit(Normal, v), v)
    p = qqnorm(v)

    @test length(p[end].plots) == 2
    plt = p[end].plots[1]
    @test plt isa Scatter
    @test first.(plt[1][]) ≈ q.qx rtol = 1e-6
    @test last.(plt[1][]) ≈ q.qy rtol = 1e-6

    plt = p[end].plots[2]
    @test plt isa LineSegments
    @test first.(plt[1][]) ≈ [extrema(q.qx)...] rtol = 1e-6
    @test last.(plt[1][]) ≈ [extrema(q.qx)...] rtol = 1e-6

    p = qqnorm(v, qqline = nothing)
    @test length(p[end].plots) == 1
    plt = p[end].plots[1]
    @test plt isa Scatter
    @test first.(plt[1][]) ≈ q.qx rtol = 1e-6
    @test last.(plt[1][]) ≈ q.qy rtol = 1e-6

    p = qqnorm(v, qqline = :fit)
    plt = p[end].plots[2]
    itc, slp = hcat(fill!(similar(q.qx), 1), q.qx) \ q.qy
    xs = [extrema(q.qx)...]
    ys = slp .* xs .+ itc
    @test first.(plt[1][]) ≈ xs rtol = 1e-6
    @test last.(plt[1][]) ≈ ys rtol = 1e-6

    p = qqnorm(v, qqline = :quantile)
    plt = p[end].plots[2]
    xs = [extrema(q.qx)...]
    quantx, quanty = quantile(q.qx, [0.25, 0.75]), quantile(q.qy, [0.25, 0.75])
    slp = diff(quanty) ./ diff(quantx)
    ys = quanty .+ slp .* (xs .- quantx)
    @test first.(plt[1][]) ≈ xs rtol = 1e-6
    @test last.(plt[1][]) ≈ ys rtol = 1e-6

end
