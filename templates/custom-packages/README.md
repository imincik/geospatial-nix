# Custom Geonix packages build

This is a example demonstrating building of customized Geonix packages using
a overrides template file.


## Usage

* Lock Flake dependencies

```
nix flake lock
```

* Add all files to git !

```
git add *
```

### Customize packages

* Run `geonix override` command to generate `overrides.nix` template file and
  add `overrides.nix` file to git.

```
nix develop --command geonix override
git add overrides.nix
```

* Enable `overridesFile` parameter in `geonix.lib.getPackages` function in
  `flake.nix` file.

* Edit `overrides.nix` file. Add changes to desired packages. Use examples on
  top of the file.

* Run `nix flake check` to check for syntax errors.

* Just re-enter development shell. Packages will be automatically rebuilt as
  necessary before shell environment is created.

```
nix develop
```

* Get customized PostgreSQL container image

```
nix build .#postgresqlImage
```

* Get customized Python container image

```
nix build .#pythonImage
```

* To return back to non-customized Geonix packages, just disable `overridesFile`
  parameter in `geonix.lib.getPackages` function.

### Geonix CLI

* Search for additional packages (run in development shell)

```
geonix search <PACKAGE>
```


## More info

* [Nix tutorials](https://nix.dev)
