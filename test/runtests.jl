using AbstractPlotting, StatsMakie, StatsBase
using Test

using Random: seed!
using AbstractPlotting.GeometryTypes: HyperRectangle
using Distributions
using FreqTables
using KernelDensity: kde

seed!(0)

@testset "boxplot" begin
    a = repeat(1:5, inner = 20)
    b = 1:100
    p = boxplot(a, b)
    plts = p[end].plots
    @test length(plts) == 4
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
        HyperRectangle{2,Float32}(Float32[0.6, 5.75], Float32[0.8, 9.5]),
        HyperRectangle{2,Float32}(Float32[1.6, 25.75], Float32[0.8, 9.5]),
        HyperRectangle{2,Float32}(Float32[2.6, 45.75], Float32[0.8, 9.5]),
        HyperRectangle{2,Float32}(Float32[3.6, 65.75], Float32[0.8, 9.5]),
        HyperRectangle{2,Float32}(Float32[4.6, 85.75], Float32[0.8, 9.5]),
    ]

    @test plts[3][1][] == poly

    #notch
    p = boxplot(a, b, notch=true)
    plts = p[end].plots

    @test length(plts) == 4

    @test plts[2] isa LineSegments
    @test plts[2][1][] == pts

    @test plts[3] isa Poly

    notch_boxes = Vector{Point{2,Float32}}[map(Point2f0, [[0.6, 5.75], [1.4, 5.75], [1.4, 7.42817], [1.2, 10.5], [1.4, 13.5718], [1.4, 15.25], [0.6, 15.25], [0.6, 13.5718], [0.8, 10.5], [0.6, 7.42817]]),
                                           map(Point2f0, [[1.6, 25.75], [2.4, 25.75], [2.4, 27.4282], [2.2, 30.5], [2.4, 33.5718], [2.4, 35.25], [1.6, 35.25], [1.6, 33.5718], [1.8, 30.5], [1.6, 27.4282]]),
                                           map(Point2f0, [[2.6, 45.75], [3.4, 45.75], [3.4, 47.4282], [3.2, 50.5], [3.4, 53.5718], [3.4, 55.25], [2.6, 55.25], [2.6, 53.5718], [2.8, 50.5], [2.6, 47.4282]]),
                                           map(Point2f0, [[3.6, 65.75], [4.4, 65.75], [4.4, 67.4282], [4.2, 70.5], [4.4, 73.5718], [4.4, 75.25], [3.6, 75.25], [3.6, 73.5718], [3.8, 70.5], [3.6, 67.4282]]),
                                           map(Point2f0, [[4.6, 85.75], [5.4, 85.75], [5.4, 87.4282], [5.2, 90.5], [5.4, 93.5718], [5.4, 95.25], [4.6, 95.25], [4.6, 93.5718], [4.8, 90.5], [4.6, 87.4282]])]
    @test plts[3][1][] ≈ notch_boxes
end

@testset "density" begin
    v = randn(1000)
    d = density(v, bandwidth = 0.1)
    p1 = plot(d)
    p2 = lines(d.x, d.density)
    @test p1[end][1][] == p2[end][1][]
    p3 = plot(density(bandwidth = 0.1), v)
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
    p4 = surface(density(bandwidth = (0.1, 0.1)), v)
    @test p4[end] isa Surface
    @test p4[end][1][] == p1[end][1][]

    t = (x = x, y = y)
    p5 = surface(density(bandwidth = (0.1, 0.1)), Data(t), (:x, :y))
    plt = p5[end].plots[1]
    @test plt isa Surface
    @test plt[1][] == p1[end][1][]

    p6 = surface(density(bandwidth = (0.1, 0.1)), Data(t), [:x :y])
    plt = p6[end].plots[1]
    @test plt isa Surface
    @test plt[1][] == p1[end][1][]

    x = randn(1000)
    y = rand(1000)
    z = rand(1:3, 1000)
    t = (x=x, y=y, z=z)
    p7 = plot(density, Data(t), Group(:z), :x, (weights = :y,))

    m1 = findall(==(1), z)
    m2 = findall(==(2), z)
    m3 = findall(==(3), z)
    k1 = kde(x[m1], weights = y[m1])
    k2 = kde(x[m2], weights = y[m2])
    k3 = kde(x[m3], weights = y[m3])
    @test p7[end].plots[1][1][] ≈ Point2f0.(k1.x, k1.density)
    @test p7[end].plots[2][1][] ≈ Point2f0.(k2.x, k2.density)
    @test p7[end].plots[3][1][] ≈ Point2f0.(k3.x, k3.density)
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

@testset "dodge" begin
    a = [1, 2, 3, 4]
    b = [1 11
         2 12
         3 13
         4 14]
    a_long = vcat(a, a)
    b_long = vec(b)
    c = [1, 1, 1, 1, 2, 2, 2, 2]

    p1 = barplot(Position.dodge, a, b)
    p2 = barplot(Position.dodge, b)
    p3 = barplot(Position.stack, a, b)
    p4 = barplot(Position.stack, Group(c), a_long, b_long)

    @test p1[end][1][] isa PlotList
    series = p1[end][1][][1]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] ≈ [0.8, 1.8, 2.8, 3.8]
    @test series[2] == [1, 2, 3, 4]
    @test series[:width] == 0.4

    series = p1[end][1][][2]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] ≈ [1.2, 2.2, 3.2, 4.2]
    @test series[2] == [11, 12, 13, 14]
    @test series[:width] == 0.4

    @test p2[end][1][] isa PlotList
    series = p2[end][1][][1]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] ≈ [0.8, 1.8, 2.8, 3.8]
    @test series[2] == [1, 2, 3, 4]
    @test series[:width] == 0.4

    series = p2[end][1][][2]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] ≈ [1.2, 2.2, 3.2, 4.2]
    @test series[2] == [11, 12, 13, 14]
    @test series[:width] == 0.4

    @test p3[end][1][] isa PlotList
    series = p3[end][1][][1]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] == [1, 2, 3, 4]
    @test series[2] == [-1, -2, -3, -4]
    @test series[:fillto] == [12, 14, 16, 18]
    @test series[:width] == 0.8

    series = p3[end][1][][2]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] == [1, 2, 3, 4]
    @test series[2] == [-11, -12, -13, -14]
    @test series[:fillto] == [11, 12, 13, 14]
    @test series[:width] == 0.8

    @test p4[end][1][] isa PlotList
    series = p4[end][1][][1]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] == [1, 2, 3, 4]
    @test series[2] == [-1, -2, -3, -4]
    @test series[:fillto] == [12, 14, 16, 18]
    @test series[:width] == 0.8

    series = p4[end][1][][2]
    @test series isa PlotSpec
    @test AbstractPlotting.plottype(series) <: BarPlot
    @test series[1] == [1, 2, 3, 4]
    @test series[2] == [-11, -12, -13, -14]
    @test series[:fillto] == [11, 12, 13, 14]
    @test series[:width] == 0.8
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

    t = (x = 1:100, y = 1:100, z = 2:2:200, m = m, c = c)
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

    colors = AbstractPlotting.wong_colors
    r = scatter(
        Data(t),
        Group(color = :c, marker = bycolumn),
        :x, (:y, :z), color = colors, marker = [:cross, :circle]
    )

    @test r[end].plots[1].color[] == colors[1]
    @test r[end].plots[2].color[] == colors[1]
    @test r[end].plots[3].color[] == colors[2]
    @test r[end].plots[4].color[] == colors[2]
    @test r[end].plots[1].marker[] == :cross
    @test r[end].plots[2].marker[] == :circle
    @test r[end].plots[3].marker[] == :cross
    @test r[end].plots[4].marker[] == :circle

    @test r[end].plots[1][1][] == Point{2, Float32}.(1:50, 1:50)
    @test r[end].plots[2][1][] == Point{2, Float32}.(1:50, 2:2:100)
    @test r[end].plots[3][1][] == Point{2, Float32}.(51:100, 51:100)
    @test r[end].plots[4][1][] == Point{2, Float32}.(51:100, 102:2:200)
end

@testset "histogram" begin
    v = randn(1000)
    h = fit(Histogram, v)
    p = plot(h)

    plt = p[end]
    @test plt isa BarPlot
    x = h.edges[1]
    @test plt[1][] ≈ Point{2, Float32}.(x[1:end-1] .+ step(x)/2, h.weights)

    v = (randn(1000), randn(1000))
    h = fit(Histogram, v, nbins = 30)
    p = plot(h)
    plt = p[end]
    @test plt isa Heatmap
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ h.weights

    p = surface(h)
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ h.weights

    p = surface(histogram(nbins = 30), v)
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ h.weights

    p = surface(histogram(nbins = 30), v...)
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ h.weights

    w = rand(1000)
    h = fit(Histogram, v, weights(w), nbins = 30)
    p = surface(histogram(nbins = 30), v..., (weights = w,))
    plt = p[end]
    @test plt isa Surface
    x = h.edges[1]
    y = h.edges[2]
    @test plt[1][] ≈ x[1:end-1] .+ step(x)/2
    @test plt[2][] ≈ y[1:end-1] .+ step(y)/2
    @test plt[3][] ≈ h.weights

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

@testset "named" begin
    v = rand(1:3, 1000)
    p = plot(freqtable, v)
    n1 = count(==(1), v)
    n2 = count(==(2), v)
    n3 = count(==(3), v)
    @test p[end] isa BarPlot
    @test p[end][1][] == Point{2, Float32}.([1, 2, 3], [n1, n2, n3])

    p = plot(frequency, v)
    @test p[end] isa BarPlot
    @test p[end][1][] == Point{2, Float32}.([1, 2, 3], [n1, n2, n3])
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

@testset "violin" begin
    x = repeat(1:4, 250)
    y = x .+ randn.()
    p = violin(x, y, side = :left, color = :blue)
    @test p[end] isa Violin
    @test p[end].plots[1] isa Mesh
    @test p[end].plots[1][:color][] == :blue
    @test p[end].plots[2] isa LineSegments
    @test p[end].plots[2][:color][] == :white
    @test p[end].plots[2][:visible][] == :false
end

@testset "errorbar" begin
    x = [1:4;]
    y =  [1:4;]
    Δx = fill(0.25, 4)
    Δy = fill(0.25, 4)
    p = errorbar(x,y,Δx,Δy,xcolor=:green,ycolor=:red)
    @test p[end] isa ErrorBar
    @test p[end][:ycolor][] == :red
    @test p[end][:xcolor][] == :green

    @test p[end].plots[1] isa ErrorBarX
    @test p[end].plots[1].plots[1] isa LineSegments
    @test p[end].plots[1][:color][] == :green

    @test p[end].plots[2] isa ErrorBarY
    @test p[end].plots[2].plots[1] isa LineSegments
    @test p[end].plots[2][:color][] == :red
end
