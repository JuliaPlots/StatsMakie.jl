module StatMakie

using Reexport
@reexport using Makie
using StatsBase
using Distributions
import IterableTables
import DataValues: DataValue
import TableTraits: column_types, column_names, getiterator, isiterabletable
import TableTraitsUtils: create_columns_from_iterabletable

export @df

include("df.jl")

end
