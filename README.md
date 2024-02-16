[![Build packages](https://github.com/imincik/geospatial-nix/actions/workflows/build-packages.yml/badge.svg)](https://github.com/imincik/geospatial-nix/actions/workflows/build-packages.yml)

# Geospatial packages repository and environment

**Geospatial NIX** provides weekly updated geospatial packages and tools built
on top of the latest stable Nixpkgs branch for creating isolated and reproducible
geospatial environments.

Check out the user interface at
[https://geospatial-nix.today/](https://geospatial-nix.today/) .


## Quick start

### Installation

* Install Nix
  [(learn more about this installer)](https://zero-to-nix.com/start/install)
```bash
curl --proto '=https' --tlsv1.2 -sSf \
    -L https://install.determinate.systems/nix \
    | sh -s -- install
  ```

### Show this repository content

* Show Geospatial NIX content
```bash
nix flake show github:imincik/geospatial-nix
```

### Run applications without installation

* Launch the latest stable QGIS version
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

nix run github:imincik/geospatial-nix#geonixcli -- init

git add *
```

* Edit `geonix.nix` file according to your project requirements
  (check out [examples](examples/) for example configurations)

* Launch shell environment
```bash
nix run .#geonixcli -- shell
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

* Build a single package and push it to the Geonix binary cache
```
nix build --json .#<PACKAGE>  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Build all packages and push them to the Geonix binary cache
```
nix build --json .#all-packages  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Run package passthru tests
```
nix build -L .#<PACKAGE>.tests.<TEST-NAME>
```

_To an re-build already built package or to re-run already succeeded tests, use the
`--rebuild` switch._

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

### Weekly development cycle

* Monday (1 AM): automatic update of base packages from latest stable Nixpkgs
  branch (nix flake update)

* Monday - Thursday: development and updates of geospatial packages in Nixpkgs
  master

* Thursday - Friday: pull from Nixpkgs master to Geospatial NIX master,
  integration, testing

* Monday (1 AM): automatic release of new version

#### Packages update process

* Create a `pkgs-weekly-update` branch and collect all package updates
  in this branch (Monday)
```bash
git checkout -b pkgs-weekly-update-$(date "+%Y-%U")
```

* Merge automatically created flake update PR (`flake-update-action-pr` branch)
  in to `pkgs-weekly-update` branch

* Pull from the latest Nixpkgs master (Thursday - Friday)
```bash
utils/pull-nixpkgs.sh <NIXPKGS-DIR>
```

* Review changes, identify related PRs in Nixpkgs, split changes to separate
  commits (link to Nixpks PR in commit message)

* Optional: generate a reverse patch for changes which are not desired
```
git diff -R <CHANGED-FILE> > pkgs/<PACKAGE>/nixpkgs/<PATCH-NAME>.patch
```

* Build and test all packages
```
nix build --json .#all-packages  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix

nix flake check

nix build --json .\#test-qgis.x86_64-linux  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
nix build --json .\#test-qgis-ltr.x86_64-linux  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Submit PR (Friday)
```
gh pr create --title "pkgs: weekly update $(date "+%Y-%U")"
```

* Merge PR (Friday or Saturday)
