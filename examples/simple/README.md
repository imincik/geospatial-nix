# Simple geospatial environment

This example provides simple environment containing following features:

* PostgreSQL/PostGIS database service
* basic geospatial CLI tools (GDAL, PDAL)
* QGIS


## Usage

_NOTE: QGIS package is disable in `devenv.nix` due to large package size.
Uncomment `geopkgs.qgis` line in `packages` configuration to enable it._

### PostgreSQL/PostGIS service

* Launch database service
```bash
  devenv up
```

### Shell environment

* Enter shell environment
```bash
  devenv shell
```

* Try GDAL
```bash
  gdalinfo --version

  GDAL 3.6.1, released 2022/12/14
```

* Connect to database
```bash
  psql
```

* Exit shell environment
```bash
  exit
```


## Geonix CLI

FIXME: `geonix search` currently doesn't work with devenv

* Search for additional packages (run in shell environment)

```bash
  geonix search <PACKAGE>
```


## More info

* [Devenv](https://devenv.sh/)
* [Nix.dev](https://nix.dev/)
