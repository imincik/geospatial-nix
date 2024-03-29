# Example Python web application

This is a example web application demonstrating development of Python
application using dependencies provided by multiple sources. This example
configuration is also automatically setting pre-commit hooks when shell
environment is launched.

Application data is provided by local Python server or by PostgreSQL/PostGIS
database backend.


## Dependencies

### Provided by Geonix

* shapely

### Provided by Nixpkgs

* matplotlib

### Provided by Poetry

* black
* flask
* isort
* pytest


## Configuration

Environment configuration is done via `geonix.nix` file. Configuration is based
on modules provided by [Devenv](https://devenv.sh/reference/options/).


## Usage

### Services (with local data backend)

* Launch services

```
nix run github:imincik/geospatial-nix#geonixcli -- shell --command geonix up
```

### Services (with database data backend)

* Launch services

```
BACKEND=db nix run github:imincik/geospatial-nix#geonixcli -- shell --command geonix up
```

### Development environment

* Enter development shell

```
nix run github:imincik/geospatial-nix#geonixcli -- shell
```

* Connect to PostgreSQL DB (optional)

```
psql
```

### Run in container

* Build container image and import it in Docker

```
nix run github:imincik/geospatial-nix#geonixcli -- container shell
```

* Run container

```
docker run --rm -p 5000:5000 shell:latest
```


### Geonix CLI

* Search for additional packages (run in shell environment)

```
geonix search <PACKAGE>
```


## More info

* [Nix documentation](https://nix.dev/)
* [Devenv](https://devenv.sh/reference/options/)
