to_tuple(t::Tuple) = t
to_tuple(t) = (t,)

function convert_arguments(P::PlotFunc, f::Function, args...; kwargs...)
    tmp = f(args...; kwargs...) |> to_tuple
    convert_arguments(P, tmp...)
end

function used_attributes(P::PlotFunc, f::Function, args...)
    x = methods(f, typeof(args))
    attr_vec = Base.kwarg_decl(first(x), typeof(x.mt.kwsorter))
    attr_vec == [Symbol("kwargs...")] ? () : Tuple(attr_vec)
end
