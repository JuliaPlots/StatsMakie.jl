using StatsMakie, IndexedTables
using Base.Test

@testset "df" begin
    t = table(1:10, 2:2:20, names = [:x, :y])
    plt = @df t scatter(:x, :y)
    @test columns(t, :x) == plt[:x]
    @test columns(t, :y) == plt[:y]
end
