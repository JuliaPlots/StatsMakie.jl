module StatsMakie

using Observables
using AbstractPlotting
import AbstractPlotting: plottype, Plot, PlotFunc, plot!, to_value, to_node, to_tuple
import AbstractPlotting: convert_arguments, used_attributes, default_theme
import AbstractPlotting: node_pairs
using Statistics, KernelDensity
import StatsBase
using Distributions
using IntervalSets
using Tables, IndexedTables
using IndexedTables: AbstractIndexedTable
using IntervalSets: Interval, endpoints

export Group, Style

include("scales.jl")
include("group.jl")
include("tables.jl")
include("density.jl")
include("histogram.jl")
include("distribution.jl")
include("corrplot.jl")
include("boxplot.jl")

end
