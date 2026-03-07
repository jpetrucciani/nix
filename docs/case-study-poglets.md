# Case Study: From Package Recipe to Running Service

This page follows one concrete example, `poglets`, through the repo. The goal is to show how the main Nix layers fit together in practice:

1. A package recipe builds software.
2. An overlay exposes it in the shared package set.
3. A module turns that package into reusable system behavior.
4. A host enables the module with machine-specific settings.
5. The flake exposes the finished machine as a buildable output.

If you understand this flow once, a large chunk of the repo stops looking mysterious.

## The Example

[`poglets`](https://github.com/jpetrucciani/poglets) is a TCP tunneling system. In this repo it appears in four important places:

- as a package recipe in [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix)
- as a reusable NixOS module in [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix)
- as an enabled service in [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix)
- as part of the buildable machine outputs exposed from [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix)

## Step 0: The Repo Builds One Shared Package Set

Before `poglets` can become `pkgs.poglets`, the repo has to build its shared package universe.

- [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) exposes outputs like packages and machine configs.
- [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix) imports the pinned `nixpkgs` input and applies overlays.
- [`overlays.nix`](https://github.com/jpetrucciani/nix/blob/main/overlays.nix) lists the local overlays that extend that package set.

The important idea is that packages, modules, hosts, and helpers all consume the same `pkgs` built by [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix), not separate ad-hoc imports.

## Step 1: The Package Recipe

The package recipe lives at [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix).

This file does the package-level job:

- fetch the source from GitHub
- declare the package name and version
- build the Go binary with `buildGo124Module`
- install shell completions
- attach metadata like description and homepage

At this point, the file explains how to build `poglets`. It does not yet say how any machine should run it.

## Step 2: The Overlay Makes It Part Of `pkgs`

The bridge from "a file under `pkgs/`" to "an attribute in the package set" is [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix).

That overlay recursively walks `pkgs/*`, calls each package file, and exposes the results as top-level attributes. That is how [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix) becomes `pkgs.poglets`.

This is one of the repo's core moves:

- package files stay organized by directory
- consumers get simple top-level names like `pkgs.poglets`

## Step 3: The Module Turns The Package Into A Service

The reusable service module lives at [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix).

This file does the module-level job:

- defines options under `services.poglets.*`
- defaults `services.poglets.package` to `pkgs.poglets`
- creates the system user and group
- declares the `systemd.services.poglets` unit
- wires the module options into the final `ExecStart`

This is the key package-vs-module distinction in practice:

- the package builds the `poglets` binary
- the module decides how `poglets` should run on a system

Because [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix) defaults the package to the `poglets` derivation exposed by [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix), a host can enable the service without manually threading the package path around.

## Step 4: A Host Chooses To Use It

The `neptune` machine imports and enables that module in [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix).

First, the host imports the module:

```nix
imports = [
  "${common.home-manager}/nixos"
  ./hardware-configuration.nix
  ../modules/servers/poglets.nix
];
```

Then it turns the feature on with machine-specific values:

```nix
services = {
  poglets = {
    enable = true;
    port = 8420;
    controlPort = 8421;
  };
};
```

This is the host-level job. [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix) is not defining how to build `poglets`, and it is not redefining the whole service. It is choosing the reusable module from [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix) and setting the values that matter for this machine.

## Step 5: The Flake Exposes A Buildable Machine

Finally, [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) exposes host configurations as flake outputs like:

- `.#nixosConfigurations.neptune.config.system.build.toplevel`

That means an outsider can build the machine configuration without understanding every implementation detail:

```bash
nix build .#nixosConfigurations.neptune.config.system.build.toplevel
```

The same [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) also exposes the package directly:

```bash
nix build .#poglets
```

That is the full chain:

```text
pkgs/server/poglets.nix
  -> mods/_pkgs.nix
    -> pkgs.poglets
      -> hosts/modules/servers/poglets.nix
        -> hosts/neptune/configuration.nix
          -> .#nixosConfigurations.neptune...
```

## What This Teaches

- A package answers "how do I build this software?"
- A module answers "how should this software be configured and run?"
- A host answers "does this specific machine use it, and with which values?"
- The flake answers "which results can outsiders build directly?"

That pattern repeats throughout the repo. Once you can see it with [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix), [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix), and [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix), you can usually spot the same structure in other packages and services.

## Try The Same Flow Yourself

If you want a safe, non-switching learning pass:

1. Read [Architecture](/architecture).
2. Read [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix).
3. Read [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix).
4. Read [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix) around the `services.poglets` block.
5. Run `nix build .#poglets`.
6. Run `nix build .#nixosConfigurations.neptune.config.system.build.toplevel`.

## Read Next

- [Learn Nix](/learn-nix)
- [Packages](/packages/index)
- [Modules](/modules/index)
- [Hosts](/hosts/index)
