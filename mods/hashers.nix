final: prev: {
  _nix_hash = with prev; with hax; repo: branch: name: (
    final.pog {
      name = "nix_hash_${name}";
      description = "grab the latest rev/sha256 from the '${branch}' branch of '${repo}'";
      flags = [
        {
          name = "branch";
          default = branch;
          description = "set the branch to pull data from. default '${branch}'";
        }
      ];
      script = ''
        ${nix-prefetch-git}/bin/nix-prefetch-git \
          --quiet \
          --no-deepClone \
          --branch-name "$branch" \
          https://github.com/${repo}.git | \
        ${jq}/bin/jq '{ date: (now|strflocaltime("%Y-%m-%d")), rev: .rev, sha256: .sha256 }'
      '';
    }
  );
  nix_hash_nixos_unstable = final._nix_hash "NixOS/nixpkgs" "nixos-unstable" "nixos_unstable";
  nix_hash_unstable = final._nix_hash "NixOS/nixpkgs" "nixpkgs-unstable" "unstable";
  nix_hash_jpetrucciani = final._nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
  nix_hash_kwb = final._nix_hash "kwbauson/cfg" "main" "kwb";
  nix_hash_hm = final._nix_hash "nix-community/home-manager" "master" "hm";
  nix_hash_darwin = final._nix_hash "LnL7/nix-darwin" "master" "darwin";
  nix_hash_medable = final._nix_hash "Medable/nix" "main" "medable";
  nix_hash_nix-security-box = final._nix_hash "fabaff/nix-security-box" "main" "nix-security-box";
  home-packages = (import ../home.nix).home.packages;
}
