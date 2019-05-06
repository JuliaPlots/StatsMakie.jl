module StatsMakie

using Observables
using AbstractPlotting
import AbstractPlotting: convert_arguments, used_attributes, plot!, combine, to_plotspec
using AbstractPlotting: plottype, Plot, PlotFunc, to_value, to_node, to_tuple
using AbstractPlotting: node_pairs, extrema_nan, automatic, default_theme
using AbstractPlotting: GeometryTypes
using Statistics, KernelDensity
import StatsBase
using Distributions
using IntervalSets
using Tables, StructArrays
using StructArrays: finduniquesorted
using IntervalSets: Interval, endpoints
using Loess
using NamedArrays: NamedArray
using FreqTables: freqtable

export Data, Group, Style
export Position
export bycolumn
export frequency

include(joinpath("group", "analysis.jl"))
include(joinpath("group", "scales.jl"))
include(joinpath("group", "group.jl"))
include(joinpath("group", "tables.jl"))
include(joinpath("group", "dodge.jl"))

include(joinpath("typerecipes", "density.jl"))
include(joinpath("typerecipes", "histogram.jl"))
include(joinpath("typerecipes", "distribution.jl"))
include(joinpath("typerecipes", "smooth.jl"))
include(joinpath("typerecipes", "namedarray.jl"))

# include(joinpath("recipes", "corrplot.jl"))
include(joinpath("recipes", "boxplot.jl"))
include(joinpath("recipes", "violin.jl"))
include(joinpath("recipes", "ribbon.jl"))
include(joinpath("recipes", "errorbar.jl"))

include(joinpath("ui", "ui.jl"))

end
