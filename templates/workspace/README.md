# Geospatial workspace

This template provides general purpose geospatial environment with multiple
shell environments containing basic geospatial CLI tools, Python environment,
QGIS, QGIS-LTR and PostgreSQL/PostGIS database.


### Shell environments

* dev: Python environment with geospatial packages, geospatial CLI tools
* postgresql: PostgreSQL/PostGIS database
* psql: PostgreSQL CLI - psql, pgcli
* pgadmin: pgAdmin web interface for PostgreSQL

### Applications

* QGIS
* QGIS-LTR


## Template initialization

```
mkdir my-project
cd my-project

git init

nix flake init --accept-flake-config --template github:imincik/geonix#workspace

nix flake lock
git add *
```


## Usage

Python and PostgreSQL versions and list of included Python packages or
PostgreSQL extensions can be configured in `flake.nix` file.


### CLI shell

* Enter shell environment
```
nix develop .#cli
```

* Try Python environment
```
[geonix] > python -c "import fiona; print(fiona.supported_drivers)"

{'DXF': 'rw', 'CSV': 'raw', 'OpenFileGDB': 'r', 'ESRIJSON': 'r', ... }
```

* Try GDAL
```
[geonix] > gdalinfo --version

GDAL 3.6.1, released 2022/12/14
```

* Try PDAL
```
[geonix] > pdal --version

pdal 2.5.0 (git-version: Release)
```

* Exit shell environment
```
exit
```

### PostgreSQL/PostGIS shell

* Launch PostGIS database in `postgresql` shell
```
nix develop .#postgresql

PostgreSQL database will start automatically.
```

* Connect to PostGIS database via `psql` shell
```
nix develop .#psql
```
```
psql -c "CREATE EXTENSION postgis";

CREATE EXTENSION
```
```
psql -c "SELECT ST_AsText(ST_Buffer(ST_GeomFromText('POINT(1 1)'), 1));"

POLYGON((2 1,1.98078528040323 0.804909677983872,1.923879532511287
0.61731656763491, ...
```

### pgAdmin shell

* Launch pgAdmin in `pgadmin` shell
```
nix develop .#pgadmin

pgAdmin will start automatically.
```

* Open pgAdmin in web browser via http://127.0.0.1:15050

### QGIS

* Launch latest stable QGIS version
```
nix run .#qgis
```

* Launch QGIS LTR version
```
nix run .#qgis-ltr
```

_NOTE: QGIS is currently available only for Linux._


## Geonix CLI

* Search for additional packages (run in development shell)

```
geonix search <PACKAGE>
```


## Customized packages

See
[CUSTOMIZED-PACKAGES.md](https://github.com/imincik/geonix/blob/master/CUSTOMIZED-PACKAGES.md)
for instructions how to customize packages.


## More info

* [Zero to Nix](https://zero-to-nix.com/)
