# Developer documentation

## Building packages

* Build single package
```bash
nix build .#<PACKAGE>
```

* Build all packages
```bash
nix build .#all-packages
```

* Run package passthru tests
```bash
nix build -L .#<PACKAGE>.tests.<TEST-NAME>
```

* Run single flake check
```bash
nix build -L .#checks.x86_64-linux.<TEST-NAME>
```

_To an re-build already built package or to re-run already succeeded tests, use the
`--rebuild` switch._

## Debugging packages

* Explore derivation
```bash
nix show-derivation .#<PACKAGE>
```

* Explore package store path content
```bash
nix path-info -rsSh .#<PACKAGE> | sort -nk3
```

* Explain package dependencies
```bash
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

* Checkout to `weekly-update` PR (PR title "pkgs: weekly update (weekly-update-<DATE>)") (Thursday - Friday)
```bash
gh pr checkout -f <PR-NUMBER>
```

* Pull from the latest Nixpkgs master
```bash
utils/pull-nixpkgs.sh <NIXPKGS-DIR>
```

* Visually review changes created by `pull-nixpkgs.sh` script
```bash
git diff
```

* Identify related PRs in Nixpkgs
```bash
git log -- <PATH-TO-PACKAGE>  # list changes to package in nixpkgs
```
```bash
gh pr list --web --state all --search <NIXPKGS-COMMIT-HASH>  # identify PR related to commit
```

* Optional: generate a reverse patch for changes which are not desired
```bash
git diff <CHANGED-FILE> > pkgs/<PACKAGE>/nixpkgs/<PATCH-NAME>.patch
```

* Create separate commit for each change (include Nixpkgs PR URL in commit message)
```bash
git commit

<PACKAGE>: <CHANGE-DESCRIPTION>

Nixpkgs PR: <NIXPKGS-PR-URL>
```

* Build, test and upload all packages to binary chache
```bash
utils/nix-build-all.sh
```

* Push changes to `weekly-update` PR
```bash
git push
```

* Merge `weekly-update` PR (Friday, Saturday)
