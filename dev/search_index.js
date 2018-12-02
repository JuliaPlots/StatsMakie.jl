var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": ""
},

{
    "location": "#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "StatsMakie attempts to combine idea from what is generally called \"Grammar of Graphics\", i.e. the ability to cleanly express in a plot how to translate variable from a dataset into graphical attributes, with the high performance interactive plotting package Makie.On top of that, StatsMakie provides a set of recipes for interactive statistical analysis (histograms, linear and non-linear regression, density plots...)."
},

{
    "location": "#Getting-started-1",
    "page": "Home",
    "title": "Getting started",
    "category": "section",
    "text": "To install StatsMakie, simply type:(v1.0) pkg> add AbstractPlotting#master Makie#master https://github.com/JuliaPlots/StatsMakie.jl.gitin the Pkg console."
},

{
    "location": "manual/tutorial/#",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "page",
    "text": ""
},

{
    "location": "manual/tutorial/#Tutorial-1",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "section",
    "text": "This tutorial shows how to create data visualizations using the StatsMakie grouping and styling APIs as well as the StatsMakie statistical recipes."
},

{
    "location": "manual/tutorial/#Grouping-data-by-discrete-variables-1",
    "page": "Tutorial",
    "title": "Grouping data by discrete variables",
    "category": "section",
    "text": "The first feature that StatsMakie adds to Makie is the ability to group data by some discrete variables and use those variables to style the result. Let\'s first create some vectors to play with:N = 1000\na = rand(1:2, N) # a discrete variable\nb = rand(1:2, N) # a discrete variable\nx = randn(N) # a continuous variable\ny = @. x * a + 0.8*randn() # a continuous variable\nz = x .+ y # a continuous variableTo see how x and y relate to each other, we could simply try (be warned: the first plot is quite slow, the following ones will be much faster):scatter(x, y, markersize = 0.2)(Image: screenshot from 2018-11-28 11-46-19)It looks like there are two components in the data, and we can ask whether they come from different values of the a variable:scatter(Group(a), x, y, markersize = 0.2)(Image: screenshot from 2018-11-28 11-45-51)Group will split the data by the discrete variable we provided and color according to that variable. Colors will cycle across a range of default values, but we can easily customize those:scatter(Group(a), x, y, color = [:black, :red], markersize = 0.2)(Image: screenshot from 2018-11-28 11-48-13)and of course we are not limited to grouping with colors: we can use the shape of the marker instead. Group(a) defaults to Group(color = a), whereas Group(marker = a) with encode the information about variable a in the marker:scatter(Group(marker = a), x, y, markersize = 0.2)(Image: screenshot from 2018-11-28 11-48-55)Grouping by many variables is also supported:scatter(Group(marker = a, color = b), x, y, markersize = 0.2)(Image: screenshot from 2018-11-28 11-53-18)"
},

{
    "location": "manual/tutorial/#Styling-data-with-continuous-variables-1",
    "page": "Tutorial",
    "title": "Styling data with continuous variables",
    "category": "section",
    "text": "One of the advantage of using an inherently discrete quantity (like the shape of the marker) to encode a discrete variable is that we can use continuous attributes (e.g. color within a colorscale) for continuous variable. In this case, if we want to see how a, x, y, z interact, we could choose the marker according to a and style the color according to z:scatter(Group(marker = a), Style(color = z), x, y)(Image: screenshot from 2018-11-28 11-50-33)Just like with Group, we can Style any number of attributes in the same plot. color is probably the most common, markersize is another sensible option (especially if we are using color already for the grouping):scatter(Group(color = a), x, y, Style(markersize = z ./ 10))(Image: screenshot from 2018-11-29 10-30-59)"
},

{
    "location": "manual/tutorial/#Split-apply-combine-strategy-with-a-plot-1",
    "page": "Tutorial",
    "title": "Split-apply-combine strategy with a plot",
    "category": "section",
    "text": "StatsMakie also has the concept of a \"visualization\" function (which is somewhat different but inspired on Grammar of Graphics statistics). The idea is that any function whose return type is understood by StatsMakie (meaning, there is an appropriate visualization for it) can be passed as first argument and it will be applied to the following arguments as well.A simple example is probably linear and non-linear regression."
},

{
    "location": "manual/tutorial/#Linear-regression-1",
    "page": "Tutorial",
    "title": "Linear regression",
    "category": "section",
    "text": "StatsMakie knows how to compute both a linear and non-linear fit of y as a function of x, via the \"analysis functions\" linear (linear regression) and smooth (local polynomial regression) respectively:using StatsMakie: linear, smooth\n\nplot(linear, x, y)(Image: screenshot from 2018-11-28 11-56-38)That was anti-climatic! It is the linear prediction of y given x, but it\'s a bit of a sad plot! We can make it more colorful by splitting our data by a, and everything will work as above:plot(linear, Group(a), x, y)(Image: screenshot from 2018-11-28 11-58-32)And then we can plot it on top of the previous scatter plot, to make sure we got a good fit:scatter(Group(a), x, y, markersize = 0.2)\nplot!(linear, Group(a), x, y)(Image: screenshot from 2018-11-28 12-00-25)Here of course it makes sense to group both things by color, but for line plots we have other options like linestyle:plot(linear, Group(linestyle = a), x, y)(Image: screenshot from 2018-11-28 12-01-54)"
},

{
    "location": "manual/tutorial/#A-non-linear-example-1",
    "page": "Tutorial",
    "title": "A non-linear example",
    "category": "section",
    "text": "Using non-linear techniques here is not very interesting as linear techniques work quite well already, so let\'s change variables:N = 200\nx = 10 .* rand(N)\na = rand(1:2, N)\ny = sin.(x) .+ 0.5 .* rand(N) .+ cos.(x) .* aand then:scatter(Group(a), x, y)\nplot!(smooth, Group(a), x, y)(Image: screenshot from 2018-11-28 12-07-31)"
},

{
    "location": "manual/tutorial/#Different-analyses-1",
    "page": "Tutorial",
    "title": "Different analyses",
    "category": "section",
    "text": "linear and smooth are two examples of possible analysis, but many more are possibles and it\'s easy to add new ones. If we were interested to the distributions of x and y for example we could do:plot(histogram, y)(Image: screenshot from 2018-11-28 12-11-43)The default plot type is determined by the dimensionality of the input and the analysis: with two variables one would get a heatmap:plot(histogram, x, y)(Image: screenshot from 2018-11-28 12-13-16)This plots is reasonably customizable in that one can pass keywords arguments to the histogram analysis:plot(histogram(nbins = 30), x, y)(Image: screenshot from 2018-11-28 12-14-19)and change the default plot type to something else:wireframe(histogram(nbins = 30), x, y)(Image: screenshot from 2018-11-28 12-15-42)Of course heatmap is the saner choice, but why not abuse Makie 3D capabilities?Other available analysis are density (to use kernel density estimation rather than binning) and frequency (to count occurrences of discrete variables)."
},

{
    "location": "manual/tutorial/#What-if-I-have-data-instead?-1",
    "page": "Tutorial",
    "title": "What if I have data instead?",
    "category": "section",
    "text": "If one has data instead, it is possible to signal StatsMakie that we are working from a DataFrame (or any table actually) and it will interpret symbols as columns:using DataFrames, RDatasets\niris = RDatasets.dataset(\"datasets\", \"iris\")\nscatter(Data(iris), Group(:Species), :SepalLength, :SepalWidth)(Image: screenshot from 2018-11-28 12-23-41)And everything else works as usual:# use Position.stack to signal that you want bars stacked vertically rather than superimposed\nplot(Position.stack, histogram, Data(iris), Group(:Species), :SepalLength)(Image: screenshot from 2018-11-28 12-27-34)wireframe(density(trim=true), Data(iris), Group(:Species), :SepalLength, :SepalWidth)(Image: screenshot from 2018-11-28 12-26-08)"
},

{
    "location": "manual/tutorial/#Wide-data-1",
    "page": "Tutorial",
    "title": "Wide data",
    "category": "section",
    "text": "Other than comparing the same column split by a categorical variable, one may also compare different columns put side by side (here in a Tuple, (:PetalLength, :PetalWidth)). The attribute that styles them has to be set to bycolumn. Here color will distinguish :PetalLength versus :PetalWidth whereas the marker will distinguish the species.scatter(\n           Data(iris),\n           Group(marker = :Species, color = bycolumn),\n           :SepalLength, (:PetalLength, :PetalWidth)\n       )(Image: screenshot from 2018-11-28 12-41-30)"
},

]}
