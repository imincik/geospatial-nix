[![Build packages](https://github.com/imincik/geospatial-nix/actions/workflows/build-packages.yml/badge.svg)](https://github.com/imincik/geospatial-nix/actions/workflows/build-packages.yml)

# A geospatial packages repository and environment

**WARNING: this project is safe to be used, but things are in active
development. Incompatible changes without any notice can occur at any time !**

**Geospatial NIX** provides weekly updated geospatial packages and tools for
creating isolated and reproducible geospatial environments.


## Quick start

### Install and configure Nix

* Install Nix
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

* Enable new Nix command interface and Nix Flakes
```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

* Add current user to Nix trusted users group
```bash
echo "trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf
```

* Restart Nix daemon
```bash
sudo systemctl restart nix-daemon.service
```

### Show content

* Show Geospatial NIX content
```bash
nix flake show github:imincik/geospatial-nix
```

### Run applications without installation

* Launch latest stable QGIS version
```bash
nix run github:imincik/geospatial-nix#qgis
```

* Launch QGIS LTR version
```bash
nix run github:imincik/geospatial-nix#qgis-ltr
```

### Create new environment

* Initialize new environment
```bash
mkdir my-project
cd my-project

git init

nix run github:imincik/geospatial-nix#geonixcli init

git add *
```

* Launch shell environment
```bash
nix run github:imincik/geospatial-nix#geonixcli shell
```

### More information about used technologies

* [Nix documentation](https://nix.dev/)
* [Devenv](https://devenv.sh/reference/options/)


## Developer documentation

### Building packages

* Build single package
```
nix build .#<PACKAGE>
```

* Build all packages
```
nix build .#all-packages
```

* Build single package and push it to Geonix binary cache
```
nix build --json .#<PACKAGE>  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Build all packages and push them to Geonix binary cache
```
nix build --json .#all-packages  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Run package passthru tests
```
nix-build -A packages.x86_64-linux.<PACKAGE>.passthru.tests
```

_To re-build already built package or to re-run already succeeded tests use
`--check` switch._

### Debugging packages

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
