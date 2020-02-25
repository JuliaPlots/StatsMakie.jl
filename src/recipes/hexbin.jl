@recipe(Hexbin, xs, ys, zs) do scene
end

function plot!(p::Hexbin)
    @extract p (xs, ys, zs)

    result = lift(xs, ys, zs) do xs, ys, zs
        
    end
end
