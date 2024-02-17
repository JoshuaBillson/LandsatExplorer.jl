module LandsatExplorer

using DataFrames, Dates, GeoFormatTypes, OrderedCollections
import HTTP, JSON, Tar, GeoJSON
using Pipe: @pipe
using Match: @match

include("types.jl")
include("utils.jl")
include("api.jl")
include("download.jl")

"""
    authenticate(username, password)

Authenticate with your USGS Earth Explorer credentials.

Sets the environment variables `LANDSAT_EXPLORER_USER` and `LANDSAT_EXPLORER_PASS`, which will
be used to authenticate future requests.

# Parameters
- `username`: Your USGS Earth Explorer username.
- `password`: Your USGS Earth Explorer password.

# Example
```julia
authenticate("my_username", "my_password")
```
"""
function authenticate(username, password)
    ENV["LANDSAT_EXPLORER_USER"] = username
    ENV["LANDSAT_EXPLORER_PASS"] = password
    return nothing
end

export Point, BoundingBox, authenticate, search, get_entity_id, download_scene, logout

end