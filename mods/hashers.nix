# This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.
final: prev:
let
  nix_hash = final.pog {
    name = "nix_hash";
    description = "grab the latest rev/sha256 from the specified repo and branch";
    strict = true;
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
      {
        name = "github_token";
        description = "GitHub API token (also passable with GITHUB_TOKEN)";
        envVar = "GITHUB_TOKEN";
        short = "";
      }
    ];
    script =
      let
        inherit (final._) curl date jq;
        nix-prefetch = "${final._nix}/bin/nix-prefetch-url";
      in
      h: ''
        if [[ ! "$repo" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
          die "repo must be in owner/repo format"
        fi

        repo_owner="''${repo%%/*}"
        branch_encoded=$(${jq} -nr --arg ref "$branch" '$ref | @uri')
        curl_args=(
          --fail-with-body
          --silent
          --show-error
          --location
          --header "Accept: application/vnd.github+json"
          --header "X-GitHub-Api-Version: 2022-11-28"
        )
        if [ -n "$github_token" ]; then
          curl_args+=(--header "Authorization: Bearer $github_token")
        fi
        response=$(${curl} "''${curl_args[@]}" "https://api.github.com/repos/$repo/commits/$branch_encoded")
        rev=$(printf '%s' "$response" | ${jq} -er '.sha | select(type == "string")')
        if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
          die "GitHub returned an invalid revision for '$repo@$branch'"
        fi

        archive_url="https://github.com/$repo/archive/$rev.tar.gz"
        sha=$(${nix-prefetch} --unpack "$archive_url")
        if [[ ! "$sha" =~ ^[0-9abcdfghijklmnpqrsvwxyz]{52}$ ]] && [[ ! "$sha" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
          die "nix-prefetch-url returned an invalid sha256 for '$archive_url'"
        fi

        d="$(${date} +%Y-%m-%d)"
        if ${h.flag "fetchtarball"}; then
          ${final.coreutils}/bin/cat <<EOF
        (fetchTarball {
          name = "$repo_owner-$d";
          url = "$archive_url";
          sha256 = "$sha";
        })
        EOF
          exit 0
        fi
        ${jq} -n \
          --arg date "$d" \
          --arg rev "$rev" \
          --arg sha256 "$sha" \
          --arg url "$archive_url" \
          '{ date: $date, rev: $rev, sha256: $sha256, url: $url }'
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

  consistentSelect = key: xs:
    let
      hex = builtins.substring 52 12 (builtins.hashString "sha256" key);
      digit = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
      n = final.lib.foldl' (acc: c: acc * 16 + digit.${c}) 0 (final.lib.stringToCharacters hex);
    in
    builtins.elemAt xs (final.lib.mod n (builtins.length xs));
}
