"""
    search(satellite, level; dates=nothing, clouds=nothing, geom=nothing, max_results=100)

Search for Landsat scenes belonging to the given satellite and processing level.

# Parameters
- `satellite`: One of "LANDSAT_5", "LANDSAT_7", or "LANDSAT_8", or "LANDSAT_9".
- `level`: The processing level; either 1 or 2.

# Keywords
- `dates`: The date range for image acquisition. Should be a tuple of `DateTime` objects.
- `clouds`: The maximum allowable cloud cover as a percentage.
- `geom`: A geometry specifying the region of interest. Can be a `Point`, `BoundingBox`, or any other `GeoInterface` compatible geometry.
- `max_results`: The maximum number of results to return (default = 100).

# Returns
A `DataFrame` with the columns `:Name`, `:AcquisitionDate`, `:PublicationDate`, `:CloudCover`, and `:Id`.

# Example
```julia
julia> p = Point(52.0, -114.2);

julia> dates = (DateTime(2020, 8, 1), DateTime(2020, 9, 1));

julia> search("LANDSAT_8", 2, dates=dates, geom=p, clouds=21)
3×5 DataFrame
 Row │ Name                               AcquisitionDate      Pub ⋯
     │ String                             String               Str ⋯
─────┼──────────────────────────────────────────────────────────────
   1 │ LC08_L2SP_043024_20200818_202008…  2020-08-18 00:00:00  202 ⋯
   2 │ LC08_L2SP_042024_20200811_202009…  2020-08-11 00:00:00  202
   3 │ LC08_L2SP_043024_20200802_202009…  2020-08-02 00:00:00  202
                                                   3 columns omitted
```
"""
function search(satellite, level; dates=nothing, clouds=nothing, geom=nothing, max_results=100)
    # Authenticate API Request
    token = api_authenticate()

    # Create Scene Filter
    scene_filter = Dict(
        "spatialFilter" => spatial_filter(geom), 
        "ingestFilter" => nothing, 
        "metadataFilter" => nothing, 
        "cloudCoverFilter" => cloud_filter(clouds), 
        "acquisitionFilter" => acquisition_filter(dates)
    )
    
    # Generate Payload
    params = Dict(
        "datasetName" => get_dataset(satellite, level),
        "sceneFilter" => scene_filter,
        "maxResults" => max_results,
        "metadataType" => "full",
    )

    # Make Request
    r = api_request("scene-search", params, token)

    # Convert Results to DataFrame
    df = r["data"]["results"] |> DataFrame

    # Throw Error if Results are Empty
    nrow(df) == 0 && throw(ErrorException("Search Returned Zero Results."))

    # Filter Landsat 8
    if satellite == "LANDSAT_8"
        DataFrames.filter!(:displayId => (x -> occursin("LC08", x)), df)
        nrow(df) == 0 && throw(ErrorException("Search Returned Zero Results."))
    end

    # Filter Landsat 9
    if satellite == "LANDSAT_9"
        DataFrames.filter!(:displayId => (x -> occursin("LC09", x)), df)
        nrow(df) == 0 && throw(ErrorException("Search Returned Zero Results."))
    end

    # Process Data
    @pipe df |>
    transform(_,:temporalCoverage => ByRow(x -> x["startDate"]) => :AcquisitionDate)|>
    _[!, [:displayId, :AcquisitionDate, :publishDate, :cloudCover, :entityId]] |>
    rename(_, :displayId => :Name, :publishDate => :PublicationDate) |>
    rename(_, :cloudCover => :CloudCover, :entityId => :Id)
end

"""
    get_entity_id(scene)

Lookup the entity ID for the given Landsat scene.

# Example
```julia
julia> LE.get_entity_id("LC08_L2SP_043024_20200802_20200914_02_T1")
"LC80430242020215LGN00"
```
"""
function get_entity_id(scene)
    # Get Token
    token = api_authenticate()

    # Create New Scene List With a Random Name
    list_id = rand('a':'z', 10) |> String
    params = Dict(
        "listId" => list_id, 
        "datasetName" => "landsat_ot_c2_l2", 
        "idField" => "displayId", 
        "entityId" => scene )
    api_request("scene-list-add", params, token)

    try
        # Get Entity ID From Scene List
        r = api_request("scene-list-get", Dict("listId" => list_id), token)
        return r["data"][1]["entityId"]
    finally
        # Remove Scene List
        api_request("scene-list-remove", Dict("listId" => list_id), token)
    end
end

"""Authenticate with the m2m API and return an access token"""
function api_authenticate()	
    login_url = "https://m2m.cr.usgs.gov/api/api/json/stable/login"
    username = get(ENV, "LANDSAT_EXPLORER_USER", "invalid")
    password = get(ENV, "LANDSAT_EXPLORER_PASS", "invalid")
    payload = Dict("username" => username, "password" => password)
    headers = Dict("Content-Type" => "application/json")
    r = HTTP.post(login_url, headers=headers, body=JSON.json(payload))
    token = @pipe r.body |> String |> JSON.parse(_)["data"]
    isnothing(token) && throw(ErrorException("User Authentication Failed!"))
    return token
end

"""Send a get request to the m2m API"""
function api_request(endpoint, params, token)
    payload = JSON.json(params)
    url = "https://m2m.cr.usgs.gov/api/api/json/stable/$endpoint"
    headers = Dict("Content-Type" => "application/json", "X-Auth-Token" => token)
    r = HTTP.request("GET", url, headers=headers, body=payload)
    return r.body |> String |> JSON.parse
end

"""Filter by acquisition date"""
function acquisition_filter(dates::Tuple{DateTime,DateTime})
    return OrderedDict(
        "start" => Dates.format(dates[1], "yyyy-mm-dd"),
        "end" => Dates.format(dates[2], "yyyy-mm-dd"), 
    )
end

function acquisition_filter(::Nothing)
    return nothing
end

"""Filter by geographic location"""
function spatial_filter(geom::BoundingBox)
    return OrderedDict(
        "filterType" => "mbr",
        "lowerLeft" => OrderedDict(
            "latitude" => geom.lr[1],
            "longitude" => geom.ul[2],
        ),
        "upperRight" => OrderedDict(
            "latitude" => geom.ul[1],
            "longitude" => geom.lr[2],
        )
    )
end

function spatial_filter(geom::Point)
    return OrderedDict(
        "filterType" => "geojson",
        "geoJson" => Dict(
            "type" => "Point", 
            "coordinates" => [geom.lon, geom.lat]
        )
    )
end

function spatial_filter(geom)
    geo_json = GeoJSON.write(geom) |> JSON.parse  # Read geom to GeoJSON
    geo_json["coordinates"] = [map(reverse, geo_json["coordinates"][1])]
    return OrderedDict(
        "filterType" => "geojson",
        "geoJson" => geo_json
    )
end

function spatial_filter(::Nothing)
    return nothing
end

"""Filter by cloud coverage"""
function cloud_filter(cloud_cover::Integer)
    return OrderedDict(
        "min" => 0, 
        "max" => cloud_cover, 
        "includeUnknown" => false
    )
end

function cloud_filter(::Nothing)
    return nothing
end