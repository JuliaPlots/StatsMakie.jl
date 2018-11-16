module StatsMakie

using Observables
using AbstractPlotting
import AbstractPlotting: plottype, Plot, PlotFunc, plot!, to_value, to_node, to_tuple
import AbstractPlotting: convert_arguments, convert_attribute, used_attributes, default_theme
import AbstractPlotting: AbstractPalette, is_cycle
using Statistics, KernelDensity
import StatsBase
using Distributions
using IntervalSets
using Tables, IndexedTables
using IndexedTables: AbstractIndexedTable
using IntervalSets: Interval, endpoints

export Group, Style

include("group.jl")
include("tables.jl")
include("density.jl")
include("histogram.jl")
include("distribution.jl")
include("corrplot.jl")
include("boxplot.jl")

end
