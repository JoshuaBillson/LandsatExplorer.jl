```@meta
CurrentModule = LandsatExplorer
```

# LandsatExplorer

[LandsatExplorer](https://github.com/JoshuaBillson/LandsatExplorer.jl) is a pure Julia package for querying and downloading Landsat data from the [USGS Earth Explorer](https://earthexplorer.usgs.gov/) ecosystem.

# Installation

To install this package, start the Julia REPL and open the package manager by typing `]`.
You can then install `LandsatExplorer` from the official Julia repository like so:

```
(@v1.9) pkg> add LandsatExplorer
```

# Authentication

`LandsatExplorer` needs access to your USGS Earth Explorer credentials in order to query and download
data. These are passed in via the environment variables `LANDSAT_EXPLORER_USER` and 
`LANDSAT_EXPLORER_PASS`. You can set them manually each time you run your program by calling 
`authenticate("my_username", "my_password")`, or you can set them once in your `startup.jl` configuration.

# Quick Start

```julia
using LandsatExplorer, GeoDataFrames, Dates

# Only Necessary if `LANDSAT_EXPLORER_USER` and `LANDSAT_EXPLORER_PASS` are not Already Set
authenticate("my_username", "my_password")

# Load Region of Interest From External GeoJSON or Shapefile
roi = GeoDataFrames.read("data/roi.geojson").geometry |> first

# Define Region of Interest as a Bounding Box
bb = BoundingBox((52.1, -114.4), (51.9, -114.1))

# Define Region of Interest Centered on a Point
p = Point(52.0, -114.25)

# Search For Level-2 Landsat 8 Imagery Intersecting our ROI Between August 1 2020 and September 1 2020
dates = (DateTime(2020, 8, 1), DateTime(2020, 9, 1))
results_1 = search("LANDSAT_8", 2, dates=dates, geom=roi)

# Limit Search to Scenes with no More Than 10% Clouds
results_2 = search("LANDSAT_8", 2, dates=dates, geom=roi, clouds=10)

# Retrieve Result with Lowest Cloud Cover
scene = sort(results_2, :CloudCover) |> first

# Download Scene
download_scene(scene.Name; unpack=true)
```

# Index

```@index
```

# API

```@autodocs
Modules = [LandsatExplorer]
Private = false
```
