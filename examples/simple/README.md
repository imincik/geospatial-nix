# Simple geospatial environment

This example provides simple environment containing following packages:

* gdal
* qgis


## Configuration

Environment configuration is done via `geonix.nix` file. Configuration is based
on modules provided by [Devenv](https://devenv.sh/reference/options/).


## Usage

* Enter shell environment
```
nix develop --impure
```

* Try GDAL
```
[geonix] > gdalinfo --version

GDAL 3.6.1, released 2022/12/14
```

* Exit shell environment
```
exit
```


## Geonix CLI

* Search for additional packages (run in shell environment)

```
geonix search <PACKAGE>
```


## More info

* [Nix documentation](https://nix.dev/)
* [Devenv](https://devenv.sh/reference/options/)
