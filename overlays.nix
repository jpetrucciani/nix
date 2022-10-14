[
  (import ./mods/hax.nix)
  (import ./mods/bashbible.nix)
  (import ./mods/fake_platform.nix)
  (import ./mods/hashers.nix)
  (import ./mods/python_pkgs.nix)
  (import ./mods/custom_pkgs.nix)
  (import ./mods/lang.nix)
  (import ./mods/pog.nix)
  (import ./mods/mods.nix)

  # sub-overlays
  (import ./mods/pkgs/caddy.nix)
  (import ./mods/pkgs/cli.nix)
  (import ./mods/pkgs/cloud.nix)
  (import ./mods/pkgs/experimental.nix)
  (import ./mods/pkgs/k8s.nix)
  (import ./mods/pkgs/server.nix)

  # pog sub-overlays
  (import ./mods/pog/atlassian.nix)
  (import ./mods/pog/aws.nix)
  (import ./mods/pog/docker.nix)
  (import ./mods/pog/ffmpeg.nix)
  (import ./mods/pog/gcp.nix)
  (import ./mods/pog/general.nix)
  (import ./mods/pog/github.nix)
  (import ./mods/pog/hax.nix)
  (import ./mods/pog/helm.nix)
  (import ./mods/pog/k8s.nix)
  (import ./mods/pog/nix.nix)
  (import ./mods/pog/python.nix)
  (import ./mods/pog/sound.nix)
  (import ./mods/pog/ssh.nix)
]
