[
  (import ./mods/hax.nix)
  (import ./mods/_pkgs.nix)
  (import ./mods/override.nix)
  (import ./mods/bashbible.nix)
  (import ./mods/fake_platform.nix)
  (import ./mods/hashers.nix)
  (import ./mods/lang.nix)
  (import ./mods/hms.nix)

  # python sub-overlays
  (import ./mods/python/default.nix)

  # ocaml sub-overlays
  (import ./mods/ocaml/default.nix)

  # sub-overlays
  (import ./mods/pkgs/ai.nix)
  (import ./mods/pkgs/cli.nix)
  (import ./mods/pkgs/cloud.nix)
  (import ./mods/pkgs/experimental.nix)
  (import ./mods/pkgs/k8s.nix)
  (import ./mods/pkgs/server.nix)
  (import ./mods/pkgs/webapp.nix)
  (import ./mods/pkgs/zaddy.nix)

  # pog sub-overlays
  (import ./mods/pog/aws.nix)
  (import ./mods/pog/db.nix)
  (import ./mods/pog/curl.nix)
  (import ./mods/pog/discord.nix)
  (import ./mods/pog/docker.nix)
  (import ./mods/pog/ebook.nix)
  (import ./mods/pog/ffmpeg.nix)
  (import ./mods/pog/gcp.nix)
  (import ./mods/pog/general.nix)
  (import ./mods/pog/github.nix)
  (import ./mods/pog/gitlab.nix)
  (import ./mods/pog/hax.nix)
  (import ./mods/pog/helm.nix)
  (import ./mods/pog/k3s.nix)
  (import ./mods/pog/k8s.nix)
  (import ./mods/pog/nix.nix)
  (import ./mods/pog/notion.nix)
  (import ./mods/pog/sound.nix)
  (import ./mods/pog/ssh.nix)

  # after all
  (import ./mods/containers.nix)
  (import ./mods/js.nix)
  (import ./mods/final.nix)
]
