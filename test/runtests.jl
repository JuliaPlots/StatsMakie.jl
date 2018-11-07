using StatsMakie
using Test

using GeometryTypes: HyperRectangle
using KernelDensity: kde
using Random: seed!

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
    d = kde(v, bandwidth = 0.1)

    p1 = lines(d)
    p2 = lines(d.x, d.density)

    @test p1[end][1][] == p2[end][1][]

    p3 = density(v, bandwidth = 0.1)

    plts = p3[end].plots

    @test length(plts) == 1
    @test plts[1] isa Lines

    @test plts[1][1][] == p1[end][1][]


    v = randn(1000, 2) 
    d = kde(v, bandwidth = (0.1, 0.1))

    p1 = heatmap(d)
    p2 = heatmap(d.x, d.y, d.density)

    @test p1[end][1][] == p2[end][1][]

    p3 = density(v, bandwidth = (0.1, 0.1))

    plts = p3[end].plots

    @test length(plts) == 1
    @test plts[1] isa Heatmap

    @test plts[1][1][] == p1[end][1][]
end