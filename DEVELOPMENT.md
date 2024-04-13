# Developer documentation

## Building packages

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

* Run single flake check
```
nix build -L .#checks.x86_64-linux.<TEST-NAME>
```

_To an re-build already built package or to re-run already succeeded tests, use the
`--rebuild` switch._

## Debugging packages

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

## Weekly development cycle

* Monday (1 AM): automatic update of base packages from latest stable Nixpkgs
  branch (nix flake update)

* Monday - Thursday: development and updates of geospatial packages in Nixpkgs
  master

* Thursday - Friday: pull from Nixpkgs master to Geospatial NIX master,
  integration, testing

* Sunday (11 PM): automatic release of new version

### Packages update process

* Create a `pkgs-weekly-update` branch to collect all package updates
  in this branch and create PR (Monday)
```bash
git checkout -b pkgs-weekly-update-$(date "+%Y.%V")

git push --set-upstream origin pkgs-weekly-update-$(date "+%Y.%V")
```

* Change base of automatically created flake update PR (`flake-update-action-pr`
  branch) and merge in in to `pkgs-weekly-update` branch

* Submit `pkgs-weekly-update` PR
```
git pull

gh pr create --title "pkgs: weekly update $(date "+%Y.%V")"
```

* Pull from the latest Nixpkgs master (Thursday - Friday)
```bash
utils/pull-nixpkgs.sh <NIXPKGS-DIR>
```

* Visually review changes created by `pull-nixpkgs.sh` script

* Identify related PRs in Nixpkgs
```
git log -- <PATH-TO-PACKAGE>  # list changes to package in nixpkgs
```
```
gh pr list --web --state all --search <NIXPKGS-COMMIT-HASH>  # identify PR related to commit
```

* Create separate commit for each change (include Nixpkgs PR URL in commit message)
```
git commit

pkgs(<PACKAGE>): <CHANGE-DESCRIPTION>

Nixpkgs PR: <NIXPKGS-PR-URL>
```

* Optional: generate a reverse patch for changes which are not desired
```
git diff <CHANGED-FILE> > pkgs/<PACKAGE>/nixpkgs/<PATCH-NAME>.patch
```

* Build, test and upload all packages to binary chache
```
nix build --json .#all-packages  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix

nix flake check

for test in test-qgis test-qgis-ltr test-nixgl; do
  nix build --json .#checks.x86_64-linux.$test | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
done
```

* Merge `pkgs-weekly-update` PR (Friday, Saturday)

* [Update packages database](https://github.com/imincik/geospatial-nix.today/actions/workflows/update-packages-db.yml) at geospatial-nix.today