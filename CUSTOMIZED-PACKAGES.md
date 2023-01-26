# Customized packages

Build definitions of all Geonix packages or container images can be overriden,
which provides possibility to build customized packages using patches, using
different build configurations or even using completely different source code.

Check out original Geonix packages [build
definitions](https://github.com/imincik/geonix/tree/master/pkgs) and change them
as needed using following steps.

Run following commands in project created from Geonix Flake template.


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

* To return back to non-customized Geonix packages, just disable `overridesFile`
  parameter in `geonix.lib.getPackages` function.


### Container images

First, container images must be added to `packages` output of the `flake.nix` file.

See following example of PostgreSQL image added to the `flake.nix` file.

Function `utils.lib.filterPackages system` and condition
`pkgs.nixpkgs.lib.optionals pkgs.nixpkgs.stdenv.isLinux` is used to ensure that
images will be built only for Linux.

```
packages = utils.lib.filterPackages system {

    # PostgreSQL/PostGIS container image
    postgresqlImage = pkgs.nixpkgs.lib.optionals pkgs.nixpkgs.stdenv.isLinux

    pkgs.geonix.geonix-postgresql-image;
};
```

* Get customized PostgreSQL container image

```
nix build .#postgresqlImage
```
