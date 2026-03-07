# snowball

`snowball` is a local overlay for packaging small bundles of systemd services and timers, then deploying them onto machines that use systemd, even if those machines are not managed as full NixOS hosts from this repo.

In practice, it is a way to take a focused bit of NixOS service configuration, render the relevant unit files, and ship them as a portable bundle with helper commands for installation and packing.

## What It Is Good For

- Shipping one or a few services to a machine that is not managed as a full host from this repo.
- Packaging targeted operational bundles like `amazon-ssm-agent`, `nvme-exporter`, or `earlyoom`.
- Reusing small service templates for scheduled jobs and long-running daemons.
- Deploying service bundles to any Linux distro that uses systemd, not only NixOS.

## Why It Is Useful

This fills an annoying gap between "just SSH in and hand-edit some unit files" and "model the entire machine as a NixOS host".

`snowball` is useful when you want:

- Reproducible systemd unit definitions.
- Small, targeted deployments instead of full-machine ownership.
- A way to reuse NixOS module logic for services on machines that are otherwise outside your Nix host inventory.
- A clean path for bundling timers, services, and their installation flow together.

## What It Produces

Each `snowball` bundle builds:

- A `/snowball` directory containing the rendered systemd unit files.
- An `install` helper that installs the bundle, links the units into `/etc/systemd/system`, reloads systemd, enables the units, and starts timers.
- A `pack` helper that builds the installer bundle so it can be shipped elsewhere.

That makes it more than a template library. It is a small deployment format for systemd-oriented service bundles.

## Typical Shapes

- One long-running service.
- One or more timers plus the services they trigger.
- A small operational feature set that you want to reuse across several machines.

The built-in examples in this repo include:

- `snowball.amazon-ssm-agent`
- `snowball.nvme-exporter`
- `snowball.earlyoom`

## Building Blocks

The local API is intentionally small:

- `snowball.templates.svc`, define a service bundle.
- `snowball.templates.job`, define a timer-driven job or a job chained from another unit.
- `snowball.tools._merge`, combine several service or job fragments into one bundle.
- `snowball.pack`, turn a focused NixOS-style config into a bundle with `install` and `pack` helpers.

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
}
```

That bundle will render the relevant service and timer units, place them under `/snowball` in the build output, and expose helper derivations for installation and packing.

This repo already exports a few real examples. For one of those, you can build the installer helper like this:

```bash
nix build .#snowball.amazon-ssm-agent.install
./result/bin/install
```

The generated installer handles the repetitive systemd setup, symlinking the rendered units into `/etc/systemd/system`, reloading systemd, enabling the units, and starting any timers in the bundle.

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
