# snowball

`snowball` is a local overlay for packaging focused systemd-oriented bundles out of NixOS-style config, then shipping those bundles onto machines that are not managed as full hosts from this repo.

It started as a way to render unit files plus a Nix-dependent installer. It now also produces a manifest, a self-contained installer script, and two RPM variants.

## What It Is Good For

- Shipping one or a few services to a machine that is not managed as a full host from this repo.
- Packaging targeted operational bundles like `amazon-ssm-agent`, `nvme-exporter`, or `earlyoom`.
- Reusing small service templates for scheduled jobs and long-running daemons.
- Reusing NixOS module logic while still producing artifacts that can be installed on RPM-based systems.

## Why It Is Useful

This fills an annoying gap between "just SSH in and hand-edit some unit files" and "model the entire machine as a NixOS host".

`snowball` is useful when you want:

- Reproducible systemd unit definitions and payload files.
- Small, targeted deployments instead of full-machine ownership.
- A way to reuse NixOS module logic for services on machines that are otherwise outside your Nix host inventory.
- A clean path for bundling timers, services, config payloads, and installation policy together.

## What It Produces

Each `snowball` bundle still builds the legacy Nix-dependent output, plus a manifest-driven packaging layer:

- The default bundle output, a `/snowball` tree of rendered unit files used by the existing `install` flow.
- `install`, the Nix-dependent helper that installs the bundle into the root profile and links units into `/etc/systemd/system`.
- `pack`, the existing helper that resolves the `install` derivation path for pushing to a cache.
- `manifest`, a JSON description of the bundle's units, staged files, closure roots, closure paths, hooks, and policy.
- `script`, a self-contained bash installer with an embedded tarball and uninstall mode.
- `rpm`, a storeful RPM that ships the runtime closure as real `/nix/store/...` files inside the package payload.
- `rpmPortable`, a relocatable RPM that copies the closure under `/usr/lib/snowball/<name>/store` and rewrites references away from `/nix/store`.
- `stage.storeful` and `stage.portable`, unpacked filesystem trees used to assemble the RPMs and useful for inspection.

That makes `snowball` more than a template library. It is a small deployment format for systemd-oriented bundles with both Nix-dependent and non-Nix-host installation paths.

## Payload Model

`snowball.pack` now models more than unit files. A bundle can include:

- systemd units
- staged files under arbitrary destinations
- `tmpfiles.d` entries
- `sysusers.d` entries
- lifecycle hooks
- lifecycle policy for enable, start, upgrade, and removal behavior

The manifest records all of that, along with the runtime closure derived from the rendered units and staged payload.

For language-runtime payloads like Python apps, there are two sane patterns here. `snowball.api` points the unit at a real interpreter and makes the dependency closure explicit in unit-file text with `python3.13` plus `PYTHONPATH`. `snowball.api-uv` takes the other route, ships the `uv` binary plus a shebang-managed PEP 723 script, and lets `uv` download Python and resolve the script environment on the target host at first start.

Unit ownership can still be auto-discovered by diffing the generated `systemd.units` against an empty config, but `units = [ ... ]` is available when you want explicit ownership instead of inference.

## RPM Variants

Two RPM backends exist because there are really two different deployment stories.

- `rpm` is the conservative path. It packages the realized runtime closure directly as `/nix/store/...` files inside the RPM payload, alongside the rendered systemd units and manifest. The target host does not need Nix installed, but the package will own Nix-style store paths.
- `rpmPortable` is the prettier path. It stages the same closure under `/usr/lib/snowball/<name>/store` and rewrites symlinks, text references, ELF interpreters, and RPATHs away from `/nix/store`.

The portable backend is still a generic relocator, not a formally complete binary relocation framework. It has been verified here with `earlyoom` and `nvme-exporter`, but wider bundles may expose more edge cases.

## Lifecycle Policy

Native package backends do not blindly enable and start everything. The current default policy is:

- `enable = "preset"`
- `start = "if-enabled"`
- `upgrade = "try-restart"`
- `remove = "disable-stop"`

That yields RPM scriptlets that reload systemd, apply `systemctl preset`, start units only when they are enabled, try-restart on upgrade, and disable plus stop managed units on erase. `/etc` payloads are preserved on uninstall.

## Typical Shapes

- One long-running service.
- One or more timers plus the services they trigger.
- A small operational feature set that you want to reuse across several machines.

The built-in examples in this repo include:

- `snowball.amazon-ssm-agent`
- `snowball.api`
- `snowball.api-uv`
- `snowball.nvme-exporter`
- `snowball.earlyoom`

## Building Blocks

The local API is still intentionally small:

- `snowball.templates.svc`, define a service bundle.
- `snowball.templates.job`, define a timer-driven job or a job chained from another unit.
- `snowball.tools._merge`, combine several service or job fragments into one bundle.
- `snowball.pack`, turn a focused NixOS-style config into a bundle with `install`, `pack`, `manifest`, `script`, `rpm`, and `rpmPortable` helpers.

## Example

This is the rough shape of a small hourly timer bundle:

```nix
let
  heartbeatJob = pkgs.snowball.templates.job {
    name = "heartbeat";
    description = "Write a timestamp once an hour";
    calendar = [ "hourly" ];
    script = ''
      mkdir -p /var/lib/heartbeat
      date --iso-8601=seconds >> /var/lib/heartbeat/timestamps.log
    '';
  };
in
pkgs.snowball.pack {
  name = "heartbeat";
  conf = pkgs.snowball.tools._merge [ heartbeatJob ];
  units = [ "heartbeat.service" "heartbeat.timer" ];
  files."/etc/default/heartbeat".text = ''
    HEARTBEAT_DIR=/var/lib/heartbeat
  '';
}
```

That bundle will render the relevant service and timer units, stage the extra file, derive a runtime manifest, and expose several installation backends.

This repo already exports a few real examples. For one of those, you can build the various outputs like this:

```bash
nix build .#snowball.earlyoom.manifest
nix build .#snowball.earlyoom.script
nix build .#snowball.earlyoom.rpm
nix build .#snowball.earlyoom.rpmPortable
nix build .#snowball.earlyoom.install
```

`install` keeps the original Nix-dependent workflow. `rpm` and `rpmPortable` are the non-Nix-host package outputs. `script` is the self-contained middle ground when you just want a single file to copy around.

## Verification

This repo now exposes Linux `checks` for two real bundles:

- `snowball.earlyoom`
- `snowball.nvme-exporter`

Those checks cover manifest generation, installer script generation, storeful RPM assembly, and portable RPM assembly.

## What To Read

- `mods/snowball.nix`
- `snowball.templates.job`
- `snowball.templates.svc`
- `snowball.pack`

## Why It Belongs In This Repo

- It extends the repo beyond full-machine management.
- It uses the same shared package set and Nix abstractions as the rest of the tree.
- It is a good example of Nix being used as a deployment tool, not only a package recipe language.
- It shows how the repo can target "any systemd box" without giving up reproducibility.

## Read Next

- [Architecture](/architecture)
- [Home Manager](/home-manager)
- [Tooling Overview](/tooling/index)
