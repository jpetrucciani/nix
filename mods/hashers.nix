prev: next: {
  _nix_hash = with next; with hax; repo: branch: name: (
    writeBashBinChecked "nix_hash_${name}" ''
      ${nix-prefetch-git}/bin/nix-prefetch-git \
        --quiet \
        --no-deepClone \
        --branch-name ${branch} \
        https://github.com/${repo}.git | \
      ${jq}/bin/jq '{ rev: .rev, sha256: .sha256 }'
    ''
  );
  nix_hash_unstable = prev._nix_hash "NixOS/nixpkgs" "nixos-unstable" "unstable";
  nix_hash_jpetrucciani = prev._nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
  nix_hash_kwb = prev._nix_hash "kwbauson/cfg" "main" "kwb";
  nix_hash_hm = prev._nix_hash "nix-community/home-manager" "master" "hm";
  nix_hash_darwin = prev._nix_hash "LnL7/nix-darwin" "master" "darwin";
  home-packages = (import ../home.nix).home.packages;
}
