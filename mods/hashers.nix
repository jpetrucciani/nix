# This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.
final: prev:
let
  nix_hash = final.pog {
    name = "nix_hash";
    description = "grab the latest rev/sha256 from the specified repo and branch";
    flags = [
      {
        name = "repo";
        description = "set the repo to pull data from.";
        required = true;
      }
      {
        name = "branch";
        description = "set the branch to pull data from.";
        default = "main";
      }
      {
        name = "fetchtarball";
        description = "print out this pin as a nix expression using fetchTarball";
        bool = true;
      }
    ];
    script =
      let
        inherit (final._) curl date jq;
        nix-prefetch = "${final._nix}/bin/nix-prefetch-url";
      in
      h: ''
        repo_owner=$(echo "$repo" | cut -d'/' -f1)
        rev=$(${curl} -s "https://api.github.com/repos/$repo/commits/$branch" | ${jq} -r '.sha')
        sha=$(${nix-prefetch} --unpack "https://github.com/$repo/archive/$rev.tar.gz")
        d="$(${date} +%Y-%m-%d)"
        if ${h.flag "fetchtarball"}; then
          cat <<EOF
        (fetchTarball {
          name = "$repo_owner-$d";
          url = "https://github.com/$repo/archive/$rev.tar.gz";
          sha256 = "$sha";
        })
        EOF
          exit 0
        fi
        echo "{ \"date\": \"$d\", \"rev\": \"$rev\", \"sha256\": \"$sha\" }" | ${jq}
      '';
  };
  _nix_hash = repo: branch: name: final.writers.writeBashBin "nix_hash_${name}" ''
    ${nix_hash}/bin/nix_hash --repo ${repo} --branch ${branch} "$@"
  '';
in
{
  inherit nix_hash;
  nix_hash_unstable = _nix_hash "NixOS/nixpkgs" "nixpkgs-unstable" "unstable";
  nix_hash_jpetrucciani = _nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
  nix_hash_hex = _nix_hash "jpetrucciani/hex" "main" "hex";
  nix_hash_pog = _nix_hash "jpetrucciani/pog" "main" "pog";
  nix_hash_adaptivereader = _nix_hash "adaptivereader/nix-ops" "main" "adaptivereader";
  nix_hash_magicschool = _nix_hash "MagicSchoolAi/nix-ops" "main" "magicschool";
  nix_hash_medable = _nix_hash "Medable/nix" "main" "medable";
  nix_hash_rust-overlay = _nix_hash "oxalica/rust-overlay" "master" "rust-overlay";
  home-packages = (import ../home.nix { }).home.packages;
}
