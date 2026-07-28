# Package patches

Each `name.nix` or `name/default.nix` file overrides the nixpkgs package named `name`.

Patch modules receive the arguments they declare from:

- `prev`: the package value from before this patch overlay
- `final`: the final package set
- `scope`: `final` extended with `final` and the package-specific `prev`
- `_overlay`: metadata containing the module `name`, `path`, `final`, and `prev`

Patch results retain the underlying package's `override` interface.
