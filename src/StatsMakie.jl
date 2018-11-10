module StatsMakie

using Reexport
@reexport using Makie
using Observables
using AbstractPlotting
import AbstractPlotting: plottype, Plot, PlotFunc, plot!, to_value, default_theme, to_node
import AbstractPlotting: convert_arguments, used_attributes
using Statistics, KernelDensity
import StatsBase
using Distributions
using Tables, IndexedTables
using IndexedTables: AbstractIndexedTable
# import IterableTables
# import DataValues: DataValue
# import TableTraits: column_types, column_names, getiterator, isiterabletable
# import TableTraitsUtils: create_columns_from_iterabletable

# export @df
export Group, Style

# include("df.jl")
include("function.jl")
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
