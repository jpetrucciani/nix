{ coreutils
, curl
, fetchurl
, installShellFiles
, jq
, lib
, nix
, stdenvNoCC
, writeShellApplication
}:
{ pname
, version
, hashes
, dataFile
, meta
, binaryName ? pname
, baseUrl ? "https://static.g7c.us/${pname}"
, latestVersionUrl ? "${baseUrl}/latest"
, installCompletions ? true
, nativeBuildInputs ? [ ]
, buildInputs ? [ ]
, binaryFixup ? ""
, enableAutoUpdate ? false
}:
let
  inherit (builtins) attrNames elem filter hasAttr length;
  inherit (lib) concatStringsSep escapeShellArg escapeShellArgs getExe optional optionalAttrs optionalString unique;

  platforms = meta.platforms or (throw "${pname}: meta.platforms is required");
  missingHashes = filter (platform: !(hasAttr platform hashes)) platforms;
  unexpectedHashes = filter (platform: !(elem platform platforms)) (attrNames hashes);
  supportedPlatforms = concatStringsSep ", " platforms;
  system = stdenvNoCC.hostPlatform.system;
  artifactHash =
    if platforms == [ ] then
      throw "${pname}: meta.platforms must not be empty"
    else if length platforms != length (unique platforms) then
      throw "${pname}: meta.platforms contains duplicate entries"
    else if missingHashes != [ ] then
      throw "${pname}: missing hashes for: ${concatStringsSep ", " missingHashes}"
    else if unexpectedHashes != [ ] then
      throw "${pname}: hashes contains unsupported platforms: ${concatStringsSep ", " unexpectedHashes}"
    else if !(elem system platforms) then
      throw "${pname}: unsupported system ${system}, supported: ${supportedPlatforms}"
    else
      hashes.${system};

  refreshScript = writeShellApplication {
    name = "refresh-${pname}";
    runtimeInputs = [
      coreutils
      curl
      jq
      nix
    ];
    text = ''
      set -euo pipefail

      if (( $# > 1 )); then
        echo "usage: refresh-${pname} [VERSION]" >&2
        exit 2
      fi

      data_file=${escapeShellArg dataFile}
      if [[ ! -f "$data_file" ]]; then
        echo "run this updater from the repository root" >&2
        exit 1
      fi

      curl_args=(
        --fail
        --location
        --silent
        --show-error
        --retry 3
      )

      version="''${1:-}"
      if [[ -z "$version" ]]; then
        version="$(curl "''${curl_args[@]}" ${escapeShellArg latestVersionUrl})"
      fi
      if [[ ! "$version" =~ ^[0-9][0-9A-Za-z._-]*$ ]]; then
        echo "invalid release version: $version" >&2
        exit 1
      fi

      base_url=${escapeShellArg baseUrl}
      binary_name=${escapeShellArg binaryName}
      platforms=( ${escapeShellArgs platforms} )
      tmp_dir="$(mktemp -d)"
      candidate=""
      cleanup() {
        rm -rf -- "$tmp_dir"
        if [[ -n "$candidate" ]]; then
          rm -f -- "$candidate"
        fi
      }
      trap cleanup EXIT
      candidate="$(mktemp "$(dirname "$data_file")/.${pname}.json.XXXXXX")"

      candidate_json="$(jq -cn --arg version "$version" '{version: $version, hashes: {}}')"
      for platform in "''${platforms[@]}"; do
        url="$base_url/$version/bin/$platform/$binary_name"
        artifact="$tmp_dir/$platform"
        curl "''${curl_args[@]}" --output "$artifact" "$url"
        if [[ ! -s "$artifact" ]]; then
          echo "downloaded artifact is empty: $url" >&2
          exit 1
        fi

        sha256="$(nix hash file --type sha256 --sri "$artifact")"
        candidate_json="$(
          jq -cn \
            --argjson current "$candidate_json" \
            --arg platform "$platform" \
            --arg sha256 "$sha256" \
            '$current | .hashes[$platform] = $sha256'
        )"
      done
      printf '%s\n' "$candidate_json" | jq --sort-keys '.' > "$candidate"

      chmod --reference="$data_file" "$candidate"
      if cmp --silent "$data_file" "$candidate"; then
        echo "${pname} is already current at $version"
        exit 0
      fi

      mv -- "$candidate" "$data_file"
      candidate=""
      echo "updated ${pname} to $version"
    '';
  };
  refreshExecutable = getExe refreshScript;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version buildInputs;

  src = fetchurl {
    url = "${baseUrl}/${finalAttrs.version}/bin/${system}/${binaryName}";
    sha256 = artifactHash;
  };

  strictDeps = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = optional installCompletions installShellFiles ++ nativeBuildInputs;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/${binaryName}"

    ${binaryFixup}

    ${optionalString installCompletions ''
      installShellCompletion --cmd ${binaryName} \
        --bash <("$out/bin/${binaryName}" completions bash) \
        --fish <("$out/bin/${binaryName}" completions fish) \
        --zsh <("$out/bin/${binaryName}" completions zsh)
    ''}

    runHook postInstall
  '';

  passthru = {
    inherit refreshScript;
  } // optionalAttrs enableAutoUpdate {
    updateScript = refreshExecutable;
  };

  meta = {
    inherit platforms;
    mainProgram = binaryName;
    maintainers = [ lib.maintainers.jpetrucciani ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  } // meta;
})
