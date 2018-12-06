using Widgets, Observables, OrderedCollections
using Widgets: div, @nodeps, Widget
using Observables: @map

function gui(df)
    t = Observable{Any}(table(df))
    names = @map collect(colnames(&t))
    maybe_names = @map vcat(Symbol(""), &names)
    x = @nodeps dropdown(names, label = "First axis")
    y = @nodeps dropdown(maybe_names, label = "Second axis")
    z = @nodeps dropdown(maybe_names, label = "Third axis")
    plot_func = @nodeps dropdown([plot, scatter, lines, barplot, heatmap, surface,
        volume, contour, boxplot, violin], label = "Plot function")
    analysis_options = OrderedDict(
        "none" => tuple,
        "density" => density,
        "histogram" => histogram,
        "linear" => linear,
        "smooth" => smooth
    )
    analysis = @nodeps dropdown(analysis_options, label = "Analysis")
    group_attr = [:color, :marker, :linestyle]
    style_attr = [:color, :markersize]
    groups = [@nodeps(dropdown(maybe_names, label = string(l))) for l in group_attr]
    styles = [@nodeps(dropdown(maybe_names, label = string(l))) for l in style_attr]
    
    output = Observable{Any}(text("Welcome to the StatsMakie GUI", align = (:center, :center)))
    
    plot_button = @nodeps(button("Plot"))
    save_button = @nodeps(button("Save"))

    ui = Widget{:gui}(
        OrderedDict(
            "plot_button" => plot_button,
            "save_button" => save_button,
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
    map!(output, plot_button) do x
        vars = Iterators.filter(!isempty∘string, [x[], y[], z[]])
        plot_func[](analysis[], Data(t[]), vars...) 
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
            style = row_style
        )
        groups = div(title("Group"), vspace, :group...)
        styles = div(title("Style"), vspace, :style...)
        bottom_row = div(_.output, hspace, groups, hspace, styles, style = row_style)
        div(top_row, vspace, button_row, vspace, bottom_row)
    end
end
    

