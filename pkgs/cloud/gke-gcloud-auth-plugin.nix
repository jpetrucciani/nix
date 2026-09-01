# gke-gcloud-auth-plugin is a required plugin for using kubectl with Google's GKE on GCP
{ stdenvNoCC
, fetchurl
, autoPatchelfHook
, lib
, writeShellApplication
, coreutils
, curl
, jq
, google-cloud-sdk
}:
let
  release = lib.importJSON ./gke-gcloud-auth-plugin.json;
  dist = release.artifacts.${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "gke-gcloud-auth-plugin";
  inherit (release) version;

  updateScript = writeShellApplication {
    name = "update-gke-gcloud-auth-plugin";
    runtimeInputs = [
      coreutils
      curl
      jq
    ];
    text = ''
      set -euo pipefail

      package_file="pkgs/cloud/gke-gcloud-auth-plugin.json"
      if [[ ! -f "$package_file" ]]; then
        echo "run this updater from the repository root" >&2
        exit 1
      fi

      gcloud_version="''${1:-${google-cloud-sdk.version}}"
      if [[ ! "$gcloud_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "invalid Google Cloud SDK version: $gcloud_version" >&2
        exit 1
      fi

      manifest="$(mktemp)"
      candidate="$(mktemp "$(dirname "$package_file")/.gke-gcloud-auth-plugin.json.XXXXXX")"
      cleanup() {
        rm -f "$manifest"
        if [[ -n "$candidate" ]]; then
          rm -f "$candidate"
        fi
      }
      trap cleanup EXIT

      manifest_url="https://dl.google.com/dl/cloudsdk/channels/rapid/components-v$gcloud_version.json"
      curl --fail --location --silent --show-error --retry 3 \
        --output "$manifest" \
        "$manifest_url"

      jq -e --sort-keys --arg expected "$gcloud_version" '
        . as $manifest |
        def one($id):
          [$manifest.components[] | select(.id == $id)] as $matches |
          if ($matches | length) == 1 then
            $matches[0]
          else
            error("expected exactly one component named \($id), found \($matches | length)")
          end;
        def artifact($id; $pluginVersion):
          one($id) as $component |
          if $component.version.version_string != $pluginVersion then
            error("component \($id) has version \($component.version.version_string), expected \($pluginVersion)")
          elif $component.data.type != "tar" then
            error("component \($id) is not a tar archive")
          elif ($component.data.source | startswith("components/google-cloud-sdk-gke-gcloud-auth-plugin-") | not) then
            error("component \($id) has an unexpected source path")
          elif ($component.data.checksum | test("^[0-9a-f]{64}$") | not) then
            error("component \($id) has an invalid SHA-256 checksum")
          else
            {
              source: $component.data.source,
              sha256: $component.data.checksum
            }
          end;
        one("gke-gcloud-auth-plugin") as $plugin |
        if $manifest.version != $expected then
          error("manifest version \($manifest.version) does not match requested version \($expected)")
        elif ($plugin.version.version_string | test("^[0-9]+\\.[0-9]+\\.[0-9]+$") | not) then
          error("plugin has an invalid version string")
        else
          {
            gcloudVersion: $manifest.version,
            manifestRevision: $manifest.revision,
            version: $plugin.version.version_string,
            artifacts: {
              "aarch64-darwin": artifact("gke-gcloud-auth-plugin-darwin-arm"; $plugin.version.version_string),
              "aarch64-linux": artifact("gke-gcloud-auth-plugin-linux-arm"; $plugin.version.version_string),
              "x86_64-linux": artifact("gke-gcloud-auth-plugin-linux-x86_64"; $plugin.version.version_string)
            }
          }
        end
      ' "$manifest" > "$candidate"

      chmod --reference="$package_file" "$candidate"
      if cmp --silent "$package_file" "$candidate"; then
        echo "gke-gcloud-auth-plugin is already current for Google Cloud SDK $gcloud_version"
        exit 0
      fi

      mv "$candidate" "$package_file"
      candidate=""
      echo "updated gke-gcloud-auth-plugin from Google Cloud SDK $gcloud_version"
    '';
  };
in
stdenvNoCC.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    inherit (dist) sha256;
    url = "https://dl.google.com/dl/cloudsdk/channels/rapid/${dist.source}";
  };

  strictDeps = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    tar xzvf ${src}
  '';
  installPhase = ''
    install -Dm755 ./bin/gke-gcloud-auth-plugin $out/bin/gke-gcloud-auth-plugin
  '';

  passthru = {
    inherit (release) gcloudVersion manifestRevision;
    updateScript = lib.getExe updateScript;
  };

  meta = {
    description = "Kubectl authentication plugin for Google Kubernetes Engine";
    homepage = "https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl";
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "gke-gcloud-auth-plugin";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
