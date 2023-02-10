# Simple configuration

This template provides simplified Flake configuration interface using
`shells.nix` configuration file.

Configuration defines following shell environments:

* **default**: default interactive shell containing GDAL and PDAL CLI and QGIS
  application

* **postgresql**: PostgreSQL service shell

* **pgadmin**: pgAdmin service shell


## Template initialization

```
mkdir my-project
cd my-project

git init

nix flake init --accept-flake-config --template github:imincik/geonix#simple

nix flake lock
git add *
```


## Usage

### Configuration file format

`shells.nix` file:

```nix
{ pkgs, geonix, ... }:

{

  packages = [

    <PACKAGE>
    <PACKAGE>

  ];


  shells = {

    <SHELL-NAME> = geonix.lib.<SHELL-FUNCTION> {
      <PARAMETERS>
    };

    <SHELL-NAME> = geonix.lib.<SHELL-FUNCTION> {
      <PARAMETERS>
    };

  };

}
```

#### packages

List of packages for default interactive shell.

* Example packages configuration
```
packages = [
  pkgs.geonix.gdal
];
```

* Enter default shell
```
nix develop
```

#### shells

List of services shells to create.

* Example shells configuration
```
shells = {

  postgresql = geonix.lib.mkPostgresqlShell {
    inherit pkgs;
    version = "postgresql_12";
  };

  pgadmin = geonix.lib.mkPgAdminShell {
    inherit pkgs;
  };

};
```

* Launch postgresql service shell
```
nix develop .#postgresql
```


### Default shell

* Enter shell environment
```
nix develop
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

### PostgreSQL/PostGIS shell

* Launch PostGIS database in `postgresql` shell
```
nix develop .#postgresql

PostgreSQL database will start automatically.
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


## More info

* [Zero to Nix](https://zero-to-nix.com/)
