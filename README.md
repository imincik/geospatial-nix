[![Build packages](https://github.com/imincik/geonix/actions/workflows/build-packages.yml/badge.svg)](https://github.com/imincik/geonix/actions/workflows/build-packages.yml)

# Geonix - a cross-platform geospatial packages distribution and development environment

**WARNING: this project is safe to run for testing, but things are in active
development. Incompatible changes without any notice can occur at any time !**


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
