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

# Index

```@index
```

# API

```@autodocs
Modules = [LandsatExplorer]
Private = false
```
