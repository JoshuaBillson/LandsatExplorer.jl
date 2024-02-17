module LandsatExplorer

using DataFrames, Dates, GeoFormatTypes, OrderedCollections
import HTTP, JSON, Tar, GeoJSON
using Pipe: @pipe
using Match: @match

include("types.jl")
include("utils.jl")
include("api.jl")
include("download.jl")

function authenticate(username, password)
    ENV["LANDSAT_EXPLORER_USER"] = username
    ENV["LANDSAT_EXPLORER_PASS"] = password
    return nothing
end

export Point, BoundingBox, authenticate, search, get_entity_id, download_scene, logout

end