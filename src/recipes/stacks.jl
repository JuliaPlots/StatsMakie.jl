# TODO: maybe generalize to always use meshscatter, e.g. for icon plots
"""
    stacks(positions, counts; kwargs...)

Plot stacks of points, using `scatter` for 2D points and `meshscatter` for 3D.

# Keyword Arguments
- `stackdim`: Dimension in which to stack dots,
- `stackratio`: Ratio of marker to stack unit, i.e. low values space markers.
- `stackoffset`: Offset of whole stack in units of points.
"""
@recipe(Stacks, points, counts) do scene
    t = Theme(;
        color = theme(scene, :color),
        strokecolor = :black,
        strokewidth = 0f0,
        stackdim = automatic,
        stackratio = 1f0,
        stackoffset = 0.5f0, # default to flush with plane
        marker = automatic,
        markersize = 1f0,
    )
    t
end

function _axis_point(P::Type{<:Point{N,T}}, v::Point{N}, i) where {N,T}
    return _axis_point(P, v[i], i)
end
function _axis_point(P::Type{<:Point{N,T}}, v, i) where {N,T}
    return P(ntuple(j -> T(v) * (j == i), N))
end

_marker_widths(x::Char) = [1f0, 1f0, 0f0]
_marker_widths(x::Symbol) = [1f0, 1f0, 0f0]
_marker_widths(x::Union{<:AbstractPlotting.HyperSphere,<:AbstractPlotting.HyperRectangle}) =
    widths(x)
function _marker_widths(x::AbstractPlotting.AbstractMesh)
    vs = x.vertices
    minv, maxv = extrema(vs)
    return Vector(abs.(maxv - minv))
end

_to_nd_scale(x, ::Any) = x
_to_nd_scale(x, ::Val{2}) = AbstractPlotting.to_2d_scale(x)
_to_nd_scale(x, ::Val{3}) = AbstractPlotting.to_3d_scale(x)

_maybe_vec(x::AbstractVector, n) = x
_maybe_vec(x, n) = fill(x, n)

function plot!(stackplot::Stacks{<:Tuple{AbstractVector{<:Point{N}},C}}) where {N,C}
    @extract stackplot (
        points,
        counts,
        stackdim,
        marker,
        markersize,
        stackratio,
        stackoffset,
        color,
        strokewidth,
        strokecolor,
    )

    scene = parent_scene(stackplot)

    outputs = lift(
        points,
        counts,
        stackdim,
        marker,
        markersize,
        stackratio,
        stackoffset,
    ) do points, counts, stackdim, marker, markersize, stackratio, stackoffset
        if stackdim === automatic
            stackdim = N
        elseif stackdim < 1 || stackdim > N
            error("Invalid stack dimension $stackdim. Must be in [1, $N]")
        end

        # pick marker and standardize
        if marker === automatic
            marker = Sphere(Point{N,Float32}(0), 0.5f0)
        end
        if N == 2
            marker = AbstractPlotting.to_spritemarker(marker)
        end

        # standardize args
        nstacks = length(points)
        markersize = _maybe_vec(markersize, nstacks)
        stackratio = _maybe_vec(stackratio, nstacks)
        stackoffset = _maybe_vec(stackoffset, nstacks)
        raw_markerwidth = _marker_widths(marker)
        markersize = _to_nd_scale.(markersize, Val(N))

        P = Point{N,Float32}
        base_points = P[]
        stack_offsets = P[] # stack offset in stack unit units
        unitheights = Float32[]
        markersizes = eltype(markersize)[]
        for (base_point, count, markersize, stackratio, stackoffset) in
            zip(points, counts, markersize, stackratio, stackoffset)
            n = Int(count)

            # get height of marker and stack unit in stackdim
            markerheight = raw_markerwidth[stackdim] * markersize[stackdim]
            unitheight = markerheight / stackratio

            # offset of base points in data units in stackdim
            baseoffset = _axis_point(P, stackoffset, stackdim) .* markerheight

            append!(stack_offsets, _axis_point.(P, 0:(count-1), stackdim))
            append!(base_points, fill(P(base_point .+ baseoffset), n))
            append!(unitheights, fill(unitheight, n))
            append!(markersizes, fill(markersize, n))
        end

        outputs = (
            base_points = base_points .+ stack_offsets .* unitheights,
            marker = marker,
            markersize = markersizes,
        )
        return outputs
    end
    base_points = @lift($outputs.base_points)
    marker = @lift($outputs.marker)
    markersize = @lift($outputs.markersize)

    scatterfun! = N == 2 ? scatter! : meshscatter!
    scatterfun!(
        stackplot,
        base_points;
        marker = marker,
        markersize = markersize,
        color = color,
        strokewidth = strokewidth,
        strokecolor = strokecolor,
    )
end

function convert_arguments(
    P::Type{<:Stacks},
    xyz::NTuple{N,<:AbstractVector{<:Number}},
    counts::AbstractVector,
) where {N}
    return convert_arguments(P, xyz..., counts)
end
function convert_arguments(
    P::Type{<:Stacks},
    x::AbstractVector{<:Number},
    counts::AbstractVector,
)
    return convert_arguments(P, x, zero(x), counts)
end
function convert_arguments(
    P::Type{<:Stacks},
    x::AbstractVector,
    y::AbstractVector,
    counts::AbstractVector,
)
    return convert_arguments(P, Point2f0.(x, y), counts)
end
function convert_arguments(
    P::Type{<:Stacks},
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    counts::AbstractVector,
)
    return convert_arguments(P, Point3f0.(x, y, z), counts)
end

function convert_arguments(P::Type{<:Stacks}, h::StatsBase.Histogram{<:Any,1})
    return convert_arguments(P, convert(Tallies, h))
end
