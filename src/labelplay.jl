to_label_entry(s) = nothing
to_label_entry(s::Symbol) = string(s)

function to_label_entry(s::Pair)
    f, l = to_label_entry.(s)
    f isa Nothing && return nothing
    "$f => $l"
end

function axisnames(st::Style)
    map(to_label_entry, Iterators.filter(t -> !isa(t, Group), to_args(st)))
end


