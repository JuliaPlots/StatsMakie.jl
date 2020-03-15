struct GLMresult{S, T}
    x::AbstractVector{S}
    y::AbstractVector{T}
    l::AbstractVector{T}
    u::AbstractVector{T}
end

function linear_confidence(x::AbstractVector{T}, y::AbstractVector{T}) where {T}
    # 
    lin_model = GLM.lm(@formula(Y ~ X), (X=x, Y=y))
    y_new, lower, upper = GLM.predict(lin_model,
     [ones(T, length(x)) x], interval=:confidence)
    # the GLM predictions always return matrices
   return GLMresult(x, y_new[:], lower[:], upper[:]) 
end

convert_arguments(P::PlotFunc, g::GLMresult) = PlotSpec{ShadedLine}(g.x, g.y, g.l, g.u)

export linear_confidence