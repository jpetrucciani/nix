# [rdpgw](https://github.com/bolkedebruin/rdpgw) is a Remote Desktop Gateway in Go for deploying on Linux/BSD/Kubernetes
{ lib
, buildGoModule
, coreutils
, fetchFromGitHub
, git
, gnused
, nix
, nix-update
, pkg-config
, pam
, unstableGitUpdater
, writeShellApplication
}:
let
  branchUpdater = unstableGitUpdater {
    url = "https://github.com/jpetrucciani/rdpgw.git";
    branch = "add_go_sum";
    tagConverter = "${lib.getExe gnused} s/^0$/2.2.0/";
  };
  updateScript = writeShellApplication {
    name = "update-rdpgw";
    runtimeInputs = [ coreutils git nix ];
    text = ''
      set -euo pipefail

      target=pkgs/server/rdpgw.nix
      branch_ref=refs/heads/add_go_sum
      if [[ ! -f "$target" ]]; then
        echo "run this updater from the repository root" >&2
        exit 1
      fi

      remote_ref="$(git ls-remote --heads https://github.com/jpetrucciani/rdpgw.git "$branch_ref")"
      if [[ "$remote_ref" == *$'\n'* || "$remote_ref" != *$'\t'"$branch_ref" ]]; then
        echo "expected exactly one $branch_ref ref" >&2
        exit 1
      fi
      latest_rev="''${remote_ref%%$'\t'*}"
      if [[ ! "$latest_rev" =~ ^[0-9a-f]{40}$ ]]; then
        echo "invalid revision for $branch_ref: $latest_rev" >&2
        exit 1
      fi

      current_rev="$(nix eval --raw --impure --expr '(import ./. {}).rdpgw.src.rev')"
      if [[ "$current_rev" == "$latest_rev" ]]; then
        echo "rdpgw is already current at $latest_rev"
        exit 0
      fi

      temporary="$(mktemp -d)"
      staged="$(mktemp "$(dirname "$target")/.rdpgw.nix.XXXXXX")"
      cleanup() {
        rm -rf -- "$temporary"
        rm -f -- "$staged"
      }
      trap cleanup EXIT

      worktree="$temporary/repo"
      cp --archive --reflink=auto . "$worktree"
      (
        cd "$worktree"
        UPDATE_NIX_ATTR_PATH=rdpgw ${lib.escapeShellArgs branchUpdater}
        ${lib.getExe nix-update} -f default.nix --version skip --no-src rdpgw
        nix build --no-link -f default.nix rdpgw
      )

      cp -- "$worktree/$target" "$staged"
      chmod --reference="$target" "$staged"
      nix-instantiate --parse "$staged" >/dev/null
      mv -- "$staged" "$target"
      echo "updated rdpgw to $latest_rev"
    '';
  };
in
buildGoModule (finalAttrs: {
  pname = "rdpgw";
  version = "2.2.0-unstable-2025-11-24";

  src = fetchFromGitHub {
    # This fork carries twelve commits beyond v2.2.0, plus a Nix-ready go.sum.
    owner = "jpetrucciani";
    repo = "rdpgw";
    rev = "2adacfdb9d6baa32adddc1acbc468b9653384a85";
    hash = "sha256-gEPAlGcjeIZ0d9nFRBFpybXt8IHlwMkT+mwD4P1C+Dc=";
  };

  vendorHash = "sha256-KH3c8IAFkXCDLleRTiTnXx+q6LpLl6oTswwmLZPUUSI=";

  patches = [ ./rdpgw-help.patch ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ pam ];

  ldflags = [ "-s" "-w" ];

  passthru.updateScript = lib.getExe updateScript;

  meta = {
    description = "Remote Desktop Gateway in Go for deploying on Linux/BSD/Kubernetes";
    homepage = "https://github.com/bolkedebruin/rdpgw";
    changelog = "https://github.com/bolkedebruin/rdpgw/compare/v2.2.0...${finalAttrs.src.rev}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "rdpgw";
  };
})
