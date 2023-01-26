# Geospatial workspace

This template provides general purpose geospatial environment with multiple
shell environments containing various CLI tools, Python environment,
applications and PostgreSQL/PostGIS database.


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

### QGIS

* Launch latest stable QGIS version
```
nix run .#qgis
```

* Launch QGIS LTR version
```
nix run .#qgis-ltr
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
