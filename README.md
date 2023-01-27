[![Build packages](https://github.com/imincik/geonix/actions/workflows/build-packages.yml/badge.svg)](https://github.com/imincik/geonix/actions/workflows/build-packages.yml)


# Geonix - cross-platform geospatial packages distribution and development environment builder

## Features

* Latest geospatial software packages for all Linux distributions, Mac and
  Windows WSL2
* Easy custom re-builds with patches, builds from PRs or custom build
  configurations
* Developer friendly container images based on latest or customized software
* Isolated and reproducible development environments per
  product/project/branch/commit
* Container images output for your applications


**WARNING: this project is safe to run for testing, but things are in active
development. Incompatible changes without any notice can occur at any time !**


Geospatial software environment is a complex system of software packages, tools
and libraries built to work together. For example [GDAL](https://gdal.org/),
[PROJ](https://proj.org/) or [GEOS](https://libgeos.org/) libraries are core
components of most of the free (and many non-free) geospatial tools, desktop
applications or database systems. Change of such core library has immediate
impact on all depending software. On traditional systems, it is very difficult
to update them without breaking whole environment.

Various components of this environment are usually coming from different sources
and in different versions depending on platform (Linux, Mac or Windows),
platform version (or Linux distribution and its version) and other additional
sources such as different Linux users repositories (PPAs, AURs, ...), Mac
Homebrew, OSGeo4W, Python PyPi, and many others.

And to make it even worse, different projects usually have different, very often
conflicting software requirements and some of them depend on customized packages.

The primary goal of Geonix project is to bring cross-platform, consistent,
declarative, reproducible and up-to-date geospatial environment for geospatial
software developers, data analysts, scientists and end users which allows to
build and run software in isolated environments as needed by particular use case
without breaking other things.


## About Nix

[Nix](https://nixos.org/) is the most advanced and unique package manager.
[Nix packages (nixpkgs)](https://github.com/NixOS/nixpkgs) is the largest collection
of up-to-date free software in the world
(see [repology comparison](https://repology.org/repositories/graphs)).

Nix runs on Linux, Mac and inside of Windows WSL with very minimal interference
with host system software and configuration.

Beside the installation of Nix package manager itself, installation of any Nix
package or project environment doesn't have any impact on the host system or
other environments. Everything what Nix installs is stored in the `/nix/store`
directory. All `/nix/store` content is stored under uniquely bit-to-bit
reproducible cryptographic hash and is shared across whole Nix system for all
components requiring that exact content.

TODO: add information how Nix software is provided to the user

Nix ecosystem offers many very unique ideas and tools which are not found
anywhere else in IT industry.


## About Geonix

Geonix is built on top of Nix, Nix packages (nixpkgs) and unique tooling provided
by this ecosystem.

Geonix is providing latest versions of the core geospatial libraries such as
GDAL, GEOS, PDAL or PROJ, growing selection of Python libraries, desktop
software like QGIS and PostgreSQL/PostGIS database system, everything always
consistently built together.

For development purposes, Geonix provides OCI compatible container images which
are always consistently built with currently used version of the environment.

Using the new Nix feature called Flakes, Geonix provides very easy way to build
isolated geospatial software environments (think about it as a Python
virtualenv, but containing all software above operating system kernel which is
required to build, test, run and package the project) which are bit-to-bit (or
bug-to-bug) reproducible on other machines using the same platform.

Whole Nix Flake environment (all software coming from nixpkgs, Geonix or other
Flakes) is pinned to the exact Git commit revision using lock file and can be
updated only when required.

New Flake projects can be started from templates and built applications can be
packaged as OCI compatible container images or can be launched directly from
source code repository (for example from GitHub).

Nix provides strong dependencies management. In case of any package changes in
the environment, Nix guarantees that all package reverse dependencies will be
automatically rebuilt. For example in case of GDAL version update or even after
any build configuration change, all reverse dependencies (like QGIS or Fiona)
are automatically rebuilt.

Nix packages are built from source code, but most of binaries are already
available either via official Nixpkgs binary cache (https://cache.nixos.org) or
Geonix binary cache (https://geonix.cachix.org).

Such environments makes software development, distribution, deployment and bug
fixing much more reliable and easier and can significantly lower the time needed
for a new developer to pick up a new project or lower the time needed to get on
speed when returning to the project after longer time period.


## Packages

For a list of Geonix maintained packages see [pkgs directory](pkgs/).


## Container images

Container images are built only for development or demonstration purposes. They
are configured with very relaxed or no authentication policies.

For a list of Geonix built container images see [imgs directory](imgs/).


## mkShell functions

Geonix provides multiple functions for building out-of-box working shell
environments.

* **mkPostgresqlShell:** PostgreSQL/PostGIS database with extensions
* **mkPsqlShell:** PostgreSQL CLI client tools
* **mkPgAdminShell:** pgAdmin web interface for PostgreSQL


## Usage

### Understanding Nix Flakes

#### Very basic Flake schema

```
A. inputs
  |
  -- configuration: list of enabled binary caches, bash prompt configuration, ...
  |
  -- inputs: list of Flake dependencies (nixpkgs, other Flakes)
```

```
B. outputs
  |
  -- packages: list of packages or container images provided by Flake
  |
  -- apps: list of applications built on top of packages
  |
  -- devShells: list of pre-configured development environments
  |
  -- templates: list of templates provided by Flake
```

Flake can use all outputs provided by input Flakes to build it's own outputs.

#### Flake commands

* **nix flake init** - create new Flake. If used with `--template`, Flake is
  created from template provided by other Flake.

* **nix develop** - enter selected development environment. This command
  also automatically builds all required packages.

* **nix build** - build package from source code if it's not present in
  local `/nix/store` directory or in any of configured binary caches.

* **nix run** - run selected application from Flake.

IMPORTANT NOTE: all files used with Flake must be added in to Git first.
Otherwise Flake is not able to see them and will throw
`No such file or directory` error message !

For in more detailed Nix and Nix Flakes documentation see
[Zero to Nix](https://zero-to-nix.com/).

### Install and configure Nix

* Install Nix on Linux, macOS or Windows
```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

* Enable new Nix command interface and Nix Flakes (on Linux)
```
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

* Add current user to Nix trusted users group
```
echo "trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf
```

* Restart Nix daemon

on Linux
```
sudo systemctl restart nix-daemon.service
```

on macOS
```
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon
```

_To uninstall Nix see
[Uninstall Nix](https://nixos.org/manual/nix/stable/installation/installing-binary.html#uninstalling) ._

### Explore Geonix Flake content

* Explore Flake content
```
nix flake show github:imincik/geonix
```

### Try applications without installation

QGIS is available only for Linux, other platforms will be available soon.

* Launch latest stable QGIS version
```
nix run github:imincik/geonix#qgis
```

* Launch QGIS LTR version
```
nix run github:imincik/geonix#qgis-ltr
```

### Install applications permanently

* Install latest stable QGIS version
```
nix profile install github:imincik/geonix#qgis
```

* Install QGIS LTR version
```
nix profile install github:imincik/geonix#qgis-ltr
```

### Try CLI shell

* Enter shell containing Python interpreter and basic geospatial CLI tools
```
nix develop github:imincik/geonix#cli
```

* Launch Python interpreter
```
[geonix] > python -c "import fiona; print(fiona.supported_drivers)"

{'DXF': 'rw', 'CSV': 'raw', 'OpenFileGDB': 'r', 'ESRIJSON': 'r', ... }
```

* Launch gdalinfo
```
[geonix] > gdalinfo --version

GDAL 3.6.1, released 2022/12/14
```

### Try Python container image

* Build container image
```
nix build github:imincik/geonix#geonix-python-image
```

* Load built image to Docker
```
docker load < ./result
```

* Run container
```
docker run --rm -u "$(id -u):$(id -g)" geonix-python -c "import fiona; print(fiona.supported_drivers)"
```

### Try PostgreSQL/PostGIS container image

* Build container image
```
nix build github:imincik/geonix#geonix-postgresql-image
```

* Load built image to Docker
```
docker load < ./result
```

* Run container
```
docker run --rm -u "$(id -u):$(id -g)" -v "$(pwd):/data" -p 15432:5432 geonix-postgresql
```

_NOTE: for reproducibility reasons, creation time of all container images is
always set to one second past the UNIX Epoch which is January 1st, 1970. Don't
be surprised if you see image created more than 50 years ago in your system._


## Templates

Geonix provides Flake templates for starting geospatial projects on top of
Geonix environment.

Current list of templates:

* [workspace](templates/workspace):
  geospatial workspace containing CLI tool, applications and
  PostgreSQL/PostGIS database

* [python-web-app](templates/python-web-app):
  example Python web application

See README file in template directory for instructions how to initialize a new
project from template and how to use it.


## Geonix development

* Build single package
```
nix build .#<PACKAGE>
```

* Build all packages
```
nix build .#all-packages
```

* Run package passthru tests
```
nix-build -A packages.x86_64-linux.<PACKAGE>.passthru.tests
```

_To re-build already built package or to re-run already succeeded tests use
`--check` switch._

* Explore derivation
```
nix show-derivation .#<PACKAGE>
```

* Explore package store path content
```
nix path-info -rsSh .#<PACKAGE> | sort -nk3
```

* Explain package dependencies
```
nix why-depends .#<PACKAGE> .#<DEPENDENCY>
```


_Credits belongs to all current and past [Nix](https://github.com/NixOS/nix/graphs/contributors),
[Nixpkgs and NixOS](https://github.com/NixOS/nixpkgs/graphs/contributors) developers and
maintainers. Thank you !_

