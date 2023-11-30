[![Build packages](https://github.com/imincik/geonix/actions/workflows/build-packages.yml/badge.svg)](https://github.com/imincik/geonix/actions/workflows/build-packages.yml)

# A cross-platform geospatial packages repository and environment

**WARNING: this project is safe to be used for testing, but things are in active
development. Incompatible changes without any notice can occur at any time !**


## Documentation

User documentation is available via
[Geonix Wiki pages](https://github.com/imincik/geonix/wiki).


## Development

* Build single package
```
nix build .#<PACKAGE>
```

* Build all packages
```
nix build .#all-packages
```

* Build single package and push it to Geonix Cachix binary cache
```
nix build --json .\#<PACKAGE>  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
```

* Build all packages and push them to Geonix Cachix binary cache
```
nix build --json .\#all-packages  | jq -r '.[].outputs | to_entries[].value' | cachix push geonix
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
