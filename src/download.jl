"""
    download_scene(scene, dir=pwd(); log_progress=true, unpack=false)

Download a Landsat scene and save to the given directory.

# Parameters
- `scene`: The display name or entity ID of the scene to be downloaded.
- `dir`: The directory in which to save the downloaded scene.

# Keywords
- `unpack`: If true, unpacks and deletes the downloaded tar file (default = false).
- `log_progress`: If true, logs the download progress at 1-second intervals (default = true).

# Returns
The path to the downloaded file(s).
"""
function download_scene(scene, dir=pwd(); log_progress=true, unpack=false)
    # Authenticate
    authenticate_download()

    # Get Data ID
    dataset = guess_dataset(scene)
    data_ids = get_data_id(dataset)

    # Get Entity ID
    entity_id = is_entity_id(scene) ? scene : get_entity_id(scene)

    # Get Download URL
    data_url = nothing
    for data_id in data_ids
        url = "https://earthexplorer.usgs.gov/download/$data_id/$entity_id/EE/"
        r = HTTP.request("GET", url, redirect=false)
        data_url = @pipe r.body |> String |> JSON.parse |> _["url"]
        !isnothing(data_url) && break
    end

    # Throw Error If Download URL Can't Be Found
    msg = "None of the Archived IDs Succeeded! Update Necessary!"
    isnothing(data_url) && throw(ArgumentError(msg))

    # Download Dataset
    update_period = log_progress ? 1 : Inf
    download_path = HTTP.download(data_url, dir, update_period=update_period)

    # Extract Tar File
    if unpack
        unzip_path = @pipe download_path |> basename |> match(r"^(.*).tar", _) |> first |> joinpath(dir, _)
        Tar.extract(download_path, unzip_path)
        rm(download_path)
        return unzip_path
    else
        return download_path
    end
end

"""Generate authentication cookies for downloading scenes"""
function authenticate_download()
    # Get CSRF Token
    auth_url = "https://ers.cr.usgs.gov/login/"
    r = HTTP.get(auth_url).body |> String
    csrf = match(r"<input type=\"hidden\" name=\"csrf\" value=\"([^\"]*)", r)[1]

    # Login
    status_code = 200
    try
        username = get(ENV, "LANDSAT_EXPLORER_USER", "invalid")
        password = get(ENV, "LANDSAT_EXPLORER_PASS", "invalid")
        data = Dict("username" => username, "password" => password, "csrf" => csrf)
        HTTP.post(auth_url, body=data)
    catch e
        if e isa HTTP.Exceptions.StatusError
            status_code = e.status
        else
            throw(e)
        end
    end
    (status_code != 200) && throw(ArgumentError("Authentication failed with code $(status_code)!"))

    # Make Sure to Logout on Exit
    if !("earthexplorer.usgs.gov" in keys(HTTP.COOKIEJAR.entries))
        atexit(logout)
    end

    # Transfer Cookies
    HTTP.COOKIEJAR.entries["earthexplorer.usgs.gov"] = HTTP.COOKIEJAR.entries["ers.cr.usgs.gov"]
    HTTP.COOKIEJAR.entries["ers.cr.usgs.gov"] = Dict{String, HTTP.Cookies.Cookie}()
end

"""Returns true if logged in to the download API"""
function logged_in()
    cookies = get(HTTP.COOKIEJAR.entries, "earthexplorer.usgs.gov", nothing)
    !isnothing(cookies) && "usgs.gov;/;EROS_SSO_production_secure" in keys(cookies)
end

"""Logout of earthexplorer; this is necessary to prevent authentication errors down the line"""
function logout()
    HTTP.get("https://earthexplorer.usgs.gov/logout", status_exception=false)
end