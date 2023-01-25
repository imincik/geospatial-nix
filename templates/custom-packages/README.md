# Custom Geonix packages build

This is a example demonstrating building of customized Geonix packages using
a overrides template file.

## Template initialization

```
mkdir my-project
cd my-project

git init

nix flake init --accept-flake-config --template github:imincik/geonix#custom-packages

nix flake lock
git add *
```


## Usage

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

* To return back to non-customized Geonix packages, just disable `overridesFile`
  parameter in `geonix.lib.getPackages` function.

### Geonix CLI

* Search for additional packages (run in development shell)

```
geonix search <PACKAGE>
```


## More info

* [Zero to Nix](https://zero-to-nix.com/)
