module StatsMakie

using Base: tail
using Observables
using AbstractPlotting
import AbstractPlotting: conversion_trait, convert_arguments, used_attributes, plot!, combine, to_plotspec
using AbstractPlotting: plottype, Plot, PlotFunc, to_tuple
using AbstractPlotting: node_pairs, extrema_nan, automatic, default_theme
using AbstractPlotting: GeometryTypes
using AbstractPlotting: ConversionTrait, el32convert, categoric_labels, categoric_position, categoric_range

# Moved in https://github.com/JuliaGizmos/Observables.jl/pull/40
if isdefined(Observables, :to_value)
    using Observables: to_value
else
    using AbstractPlotting: to_value
end


using Statistics, KernelDensity
import StatsBase
using Distributions
using IntervalSets
using Tables, StructArrays
using StructArrays: uniquesorted, finduniquesorted, GroupPerm
using IntervalSets: Interval, endpoints
using Loess

export Data, Group, Style
export Position
export bycolumn
export frequency

include(joinpath("group", "scales.jl"))
include(joinpath("group", "grammarspec.jl"))
include(joinpath("group", "convert_arguments.jl"))
include(joinpath("group", "dodge.jl"))

include(joinpath("typerecipes", "density.jl"))
include(joinpath("typerecipes", "histogram.jl"))
include(joinpath("typerecipes", "distribution.jl"))
include(joinpath("typerecipes", "smooth.jl"))
include(joinpath("typerecipes", "namedarray.jl"))

include(joinpath("recipes", "conversions.jl"))
# include(joinpath("recipes", "corrplot.jl"))
include(joinpath("recipes", "boxplot.jl"))
include(joinpath("recipes", "violin.jl"))
include(joinpath("recipes", "ribbon.jl"))
include(joinpath("recipes", "errorbar.jl"))

end
