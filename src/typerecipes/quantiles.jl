# Port of R's ppoints function for ordinates for probability plotting
# http://stat.ethz.ch/R-manual/R-patched/library/stats/html/ppoints.html
_ppoints(n, a = n ≤ 10 ? 3 / 8 : 1 / 2) = (1:(n-1).-a) ./ (n - 2a)

function _quantiles(x; p = automatic, n = 100, weights = automatic, sorted = false)
    p = p === automatic ? _ppoints(n) : p
    ws = weights === automatic ? () : (Ref(weights),)
    x = sorted ? x : sort(x)
    qs = StatsBase.quantile.(Ref(x), ws..., p; sorted = true)
    return qs
end
function _quantiles(x, y; kwargs...)
    xs = eltype(x)[]
    qs = float(eltype(y))[]
    for (key, idxs) in finduniquesorted(x)
        v = view(y, idxs)
        qvs = _quantiles(v; kwargs...)
        append!(xs, fill(key, length(qvs)))
        append!(qs, qvs)
    end
    return xs, qs
end

const quantiles = Analysis(_quantiles)
export quantiles
