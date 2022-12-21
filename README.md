![Build and populate cache](https://github.com/imincik/geonix/workflows/Build%20and%20populate%20cache/badge.svg)
[![Cachix Cache](https://img.shields.io/badge/cachix-geonix-blue.svg)](https://geonix.cachix.org)

# Geonix - geospatial environment

Geospatial software environment is a complex system of software packages, tools
and libraries wired together. For example [GDAL](https://gdal.org/) library is a
core component of most of free and many non-free geospatial software. Change of
one component has immediate impact on other depending components. It is not
trivial task to manage such system and keep it up-to-date.

Using [Nix](https://nixos.org/) - the most advanced package manager and [Nix
packages (nixpkgs)](https://github.com/NixOS/nixpkgs) - the largest collection
of free software in the world (currently counting around 80000 packages) we can
deliver high quality, easy to access and always up-to-date geospatial
environment for users and developers running any Linux distribution, Mac (soon)
and Windows WSL.

I addition, Nix offers unique features like building complete and isolated
software environments per-project (think about it as Python virtualenv, but for
all software above operating system kernel required to build, test and run your
project) which are bit-to-bit reproducible on other machines at any time in the
future. This can significantly lower the time needed for a new developer to
start with new project or time needed to get on speed when returning to the
project after longer time period. This also makes software distribution,
deployment and bug fixing more reliable and easier.

Beside the installation of Nix package manager itself, installation of any Nix
packages or environments doesn't have any impact on host system and all changes
are easily reversible. It is fine to install a program, for example latest
version of QGIS (and all its dependencies) from Geonix, in addition to QGIS
installation coming from Linux system native package manager. There will be no
QGIS or other dependencies conflicts.


## Packages

For a list of maintained packages see [pkgs directory](pkgs/).


## Usage

### Install and configure Nix

* Install Nix on non-NixOS Linux (Ubuntu, Fedora, ...)
```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

* Enable new Nix command and Nix Flakes
```
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

* Add current user to Nix trusted users group
```
echo "trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf
```

* Restart Nix daemon
```
sudo systemctl restart nix-daemon.service
```

_For Nix installation on Mac or Windows (WSL2) see
[Install Nix documentation](https://nix.dev/tutorials/install-nix#install-nix) ._

### This Flake content

* Show this Flake content
```
nix flake show                                      # from local git checkout


nix flake show github:imincik/geonix                # from GitHub
```


### Run applications without installation

* Launch latest stable QGIS version
```
nix run .#qgis                                      # from local git checkout

nix run github:imincik/geonix#qgis                  # from GitHub
```

* Launch QGIS LTR version
```
nix run .#qgis-ltr                                  # from local git checkout

nix run github:imincik/geonix#qgis-ltr              # from GitHub
```

### Install applications permanently

* Install latest stable QGIS version
```
nix profile install .#qgis                          # from local git checkout

nix profile install github:imincik/geonix#qgis      # from GitHub
```

* Install QGIS LTR version
```
nix profile install .#qgis-ltr                      # from local git checkout

nix profile install github:imincik/geonix#qgis-ltr  # from GitHub
```

### Geonix shell

* Enter shell containing Geonix applications, CLI tools and Python interpreter
```
nix develop                                         # from local git checkout

nix develop github:imincik/geonix                   # from GitHub
```

* Launch QGIS
```
[geonix] > qgis
```

* Launch gdalinfo
```
[geonix] > gdalinfo --version

GDAL 3.6.1, released 2022/12/14
```

* Launch Python interpreter
```
[geonix] > python -c "import fiona; print(fiona.supported_drivers)"

{'DXF': 'rw', 'CSV': 'raw', 'OpenFileGDB': 'r', 'ESRIJSON': 'r', ... }
```


## Development

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

* Explore package store path content
```
nix path-info -rsSh .#<PACKAGE> | sort -nk3
```

* Explain package dependencies
```
nix why-depends .#<PACKAGE> .#<DEPENDENCY>
```
