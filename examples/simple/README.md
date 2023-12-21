# Simple geospatial environment

This example provides simple environment containing following packages:

* gdal
* qgis


## Configuration

Environment configuration is done via `geonix.nix` file. Configuration is based
on modules provided by [Devenv](https://devenv.sh/reference/options/).


## Usage

### Development environment

* Enter shell environment
```
nix run github:imincik/geospatial-nix#geonixcli -- shell
```

* Try GDAL
```
[geonix] > gdalinfo --version

GDAL 3.6.1, released 2022/12/14
```

### Run in container

* Build container image and import it in Docker

```
nix run github:imincik/geospatial-nix#geonixcli -- container shell
```

* Run container

```
docker run --rm -it shell:latest gdalinfo --version
```


## Geonix CLI

* Search for additional packages (run in shell environment)

```
geonix search <PACKAGE>
```


## More info

* [Nix documentation](https://nix.dev/)
* [Devenv](https://devenv.sh/reference/options/)
