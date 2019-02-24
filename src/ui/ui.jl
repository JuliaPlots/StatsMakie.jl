using Widgets, Observables, OrderedCollections
using Widgets: div, @nodeps, Widget, dropdown, button, textbox
using Observables: @map, AbstractObservable
import FileIO

_empty(s::AbstractString) = s == ""
_empty(s::Symbol) = s == Symbol("")
_empty(p::Pair) = _empty(last(p))
exclude_empty(v) = Iterators.filter(!_empty, v)

function gui(df)
    df isa AbstractObservable || (df = Observable{Any}(df))
    t = map(columntable, df)
    names = @map collect(propertynames(&t))
    maybe_names = @map vcat(Symbol(""), &names)
    x = dropdown(names, label = "First axis")
    y = dropdown(maybe_names, label = "Second axis")
    z = dropdown(maybe_names, label = "Third axis")
    plot_func = dropdown([plot, scatter, lines, barplot, heatmap, surface, wireframe,
        volume, contour, boxplot, violin], label = "Plot function")
    analysis_options = OrderedDict(
        "" => tuple,
        "density" => density,
        "histogram" => histogram,
        "linear" => linear,
        "smooth" => smooth
    )
    analysis = dropdown(analysis_options, label = "Analysis")
    group_attr = [:color, :marker, :linestyle]
    style_attr = [:color, :markersize]
    groups = [dropdown(maybe_names, label = string(l)) for l in group_attr]
    styles = [dropdown(maybe_names, label = string(l)) for l in style_attr]

    output = Observable{Any}(text("Welcome to the StatsMakie GUI", align = (:center, :center)))

    plot_button = button("Plot")
    save_button = button("Save")
    save_name = textbox(placeholder = "Save as...")

    ui = Widget{:gui}(
        OrderedDict(
            "plot_button" => plot_button,
            "save_button" => save_button,
            "save_name" => save_name,
            "table" => t,
            "plot_func" => plot_func,
            "analysis" => analysis,
            "x" => x,
            "y" => y,
            "z" => z,
            "group" => groups,
            "style" => styles
        ),
        output = output
    )
    map!(output, plot_button) do _
        vars = exclude_empty([x[], y[], z[]])
        grps = exclude_empty([(key => val[]) for (key, val) in zip(group_attr, groups)])
        stls = exclude_empty((key => val[]) for (key, val) in zip(style_attr, styles))
        g = Group(; grps...)
        s = Style(; stls...)
        plot_func[](analysis[], Data(t[]), g, s, vars...)
    end
    on(save_button) do _
        save_plot(save_name[], output[])
    end
    row_style = Dict("display" => "flex", "direction" => "row")
    column_style = Dict("display" => "flex", "direction" => "column")
    title = t -> Widgets.node("p", t, style = Dict("font-weight" => "bold"))
    hspace = div(style = Dict("width" => "1em"))
    vspace = div(style = Dict("height" => "1em"))
    @layout! ui begin
        top_row = div(
            :plot_func,
            hspace,
            :analysis,
            hspace,
            :x,
            hspace,
            :y,
            hspace,
            :z,
            style = row_style
        )
        button_row = div(
            :plot_button,
            hspace,
            :save_button,
            hspace,
            :save_name,
            style = row_style
        )
        group_column = div(title("Group"), vspace, :group...)
        style_column = div(title("Style"), vspace, :style...)
        bottom_row = div(_.output, hspace, group_column, hspace, style_column, style = row_style)
        div(top_row, vspace, button_row, vspace, bottom_row)
    end
end

function save_plot(name, scene)
    fp = joinpath(homedir(), ".StatsMakie", "plots")
    ispath(fp) || mkpath(fp)
    FileIO.save(joinpath(fp, name), scene)
end
