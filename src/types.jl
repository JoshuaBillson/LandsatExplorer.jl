"""
    BoundingBox(ul, lr)

Construct a bounding box defined by the corners `ul` and `lr`.

All coordinates should be provided in latitude and longitude.

# Parameters
- `ul`: The upper-left corner of the box as a `Tuple{T,T}` of latitude and longitude.
- `lr`: The lower-right corner of the box as a `Tuple{T,T}` of latitude and longitude.

# Example
```julia
bb = BoundingBox((52.1, -114.4), (51.9, -114.1))
```
"""
struct BoundingBox{T}
    ul::Tuple{T,T}
    lr::Tuple{T,T}
    BoundingBox(ul::Tuple{T,T}, lr::Tuple{T,T}) where {T} = new{T}(ul, lr)
end

"""
    Point(lat, lon)

Construct a point located at the provided latitude and longitude.

# Parameters
- `lat`: The latitude of the point.
- `lon`: The longitude of the point.

# Example
```julia
p = Point(52.0, -114.25)
```
"""
struct Point{T}
    lat::T
    lon::T
    Point(lat::T, lon::T) where {T} = new{T}(lat, lon)
end
