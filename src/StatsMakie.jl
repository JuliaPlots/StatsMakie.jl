module StatsMakie

using Reexport
@reexport using Makie
using Observables
using AbstractPlotting
import AbstractPlotting: convert_arguments, plottype, Plot, plot!, to_value, default_theme, to_node
using Statistics, KernelDensity
import StatsBase
using Distributions
using Tables, IndexedTables
# import IterableTables
# import DataValues: DataValue
# import TableTraits: column_types, column_names, getiterator, isiterabletable
# import TableTraitsUtils: create_columns_from_iterabletable

# export @df
export Group

# include("df.jl")
include("scales.jl")
include("group.jl")
include("utils.jl")
include("density.jl")
include("histogram.jl")
include("distribution.jl")
include("corrplot.jl")
include("boxplot.jl")

end
