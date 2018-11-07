to_label_entry(s) = nothing
to_label_entry(s::Symbol) = string(s)

function to_label_entry(s::Pair)
    f, l = to_label_entry.(s)
    f isa Nothing && return nothing
    "$f => $l"
end

function to_legend(st::Style)
    map(to_label_entry, to_args(st))
end

using StatsMakie
N = 20

scatter(
    Group(
        color = rand(Bool, 10),
        marker = rand(Bool, 10),
    ),
    rand(10),
    rand(10),
    color = [:blue, :red],
    marker = [:cross, :circle]
)
scatter(
    Group(color = rand(1:4, N), marker = rand(Bool, N)),
    rand(N),
    rand(N)
)
using RDatasets

using RDatasets
mpg = RDatasets.dataset("ggplot2", "mpg")
p1 = scatter(mpg,                                                    
    Group(marker = :Class),                              
    Style(:Displ, :Hwy), Style(color = :Hwy),  markersize = 1,  
)
new_theme = Theme(
    scatter = Theme(marker = [:cross, :diamond])
)
AbstractPlotting.set_theme!(new_theme)
p2 = scatter(mpg,                                                    
    Group(marker = :Class),                              
    Style(:Displ, :Hwy), Style(color = :Hwy),  markersize = 1,  
)
vbox(p1, p2)
# TODO add tests (fix those that exist)
# TODO for grouping allow preprocessing to happen to scale!
# TODO check that all themes are given correctly
# TODO use color = instead of scale
# TODO implement to_legend
methods(exp)
using Makie
scene = Scene(resolution = (500, 500));
x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegments!(
       range(1, stop = 5, length = 100), rand(100), rand(100),
       linestyle = ls, linewidth = lw,
       color = rand(RGBAf0)
   )[end]
end;
x = [x..., scatter!(range(1, stop=5, length=100), rand(100), rand(100))[end]]
center!(scene)
ls = Makie.legend(x, ["attribute $i" for i in 1:4], camera = campixel!, raw = true)
vbox(scene, ls)