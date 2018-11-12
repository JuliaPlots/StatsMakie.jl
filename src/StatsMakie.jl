module StatsMakie

using Reexport
@reexport using Makie
using Observables
using AbstractPlotting
import AbstractPlotting: plottype, Plot, PlotFunc, plot!, to_value, to_node, to_tuple
import AbstractPlotting: convert_arguments, used_attributes, default_theme
using Statistics, KernelDensity
import StatsBase
using Distributions
using Tables, IndexedTables
using IndexedTables: AbstractIndexedTable

export Group, Style

include("scales.jl")
include("group.jl")
include("tables.jl")
include("utils.jl")
include("density.jl")
include("histogram.jl")
include("distribution.jl")
include("corrplot.jl")
include("boxplot.jl")

end
