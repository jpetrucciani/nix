# This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.
final: prev: {
  _nix_hash = repo: branch: name: (
    final.pog {
      name = "nix_hash_${name}";
      description = "grab the latest rev/sha256 from the '${branch}' branch of '${repo}'";
      flags = [
        {
          name = "branch";
          default = branch;
          description = "set the branch to pull data from. default '${branch}'";
        }
        {
          name = "fetchtarball";
          description = "print out this pin as a nix expression using fetchTarball";
          bool = true;
        }
      ];
      script =
        let
          curl = final._.curl;
          date = final._.date;
          jq = final._.jq;
          nix-prefetch = "${final._._nix}/bin/nix-prefetch-url";
        in
        h: ''
          rev=$(${curl} -s "https://api.github.com/repos/${repo}/commits/$branch" | ${jq} -r '.sha')
          sha=$(${nix-prefetch} --unpack "https://github.com/${repo}/archive/$rev.tar.gz")
          d="$(${date} +%Y-%m-%d)"
          if ${h.flag "fetchtarball"}; then
            cat <<EOF
          (fetchTarball {
            name = "${name}-$d";
            url = "https://github.com/${repo}/archive/$rev.tar.gz";
            sha256 = "$sha";
          })
          EOF
            exit 0
          fi
          echo "{ \"date\": \"$d\", \"rev\": \"$rev\", \"sha256\": \"$sha\" }" | ${jq}
        '';
    }
  );
  nix_hash_unstable = final._nix_hash "NixOS/nixpkgs" "nixpkgs-unstable" "unstable";
  nix_hash_jpetrucciani = final._nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
  nix_hash_medable = final._nix_hash "Medable/nix" "main" "medable";
  home-packages = (import ../home.nix { }).home.packages;
}
