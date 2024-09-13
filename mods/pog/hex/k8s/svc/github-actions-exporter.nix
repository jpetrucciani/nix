{ hex, pkgs, ... }:
{ name ? "github-actions-exporter"
, namespace ? "default"
, image_registry ? "ghcr.io"
, image_base ? "labbs/github-actions-exporter"
, image_tag ? "1.9.0"
, image ? "${image_registry}/${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, port ? 9999
, labels ? {
    inherit name;
    upstream = "github-actions";
    tier = "exporter";
  }
, extraService ? { } # escape hatch to inject other service spec
, secret ? ""
, githubToken ? ""
, githubAppId ? ""
, githubAppInstallationId ? ""
, githubPrivateKeySecret ? ""
, githubPrivateKeySecretKey ? "github.pem"
, githubOrgas ? ""
, githubRepos ? ""
, githubApiUrl ? "api.github.com"
, githubRefresh ? 30
, githubExportFields ? "repo,id,node_id,head_branch,head_sha,run_number,workflow_id,workflow,event,status"
}:
let
  inherit (pkgs.lib) recursiveUpdate;
  volumes = [
    hex.k8s.services.components.volumes.tmp
  ] ++ (if usingApp then [{ name = "private-key"; secret = githubPrivateKeySecret; mountPath = "/secrets"; }] else [ ]);
  usingToken = githubToken != "";
  usingApp = githubAppId != "" && githubAppInstallationId != "" && githubPrivateKeySecret != "" && githubPrivateKeySecretKey != "";
in
assert githubApiUrl != "";
assert usingToken -> !usingApp;
assert usingApp -> !usingToken;
hex.k8s.services.build (
  recursiveUpdate
  {
    inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes;
    envAttrs = {
      GITHUB_API_URL = githubApiUrl;
      GITHUB_REFRESH = toString githubRefresh;
      ${if githubRepos != "" then "GITHUB_REPOS" else null} = githubRepos;
      ${if githubOrgas != "" then "GITHUB_ORGAS" else null} = githubOrgas;
      EXPORT_FIELDS = githubExportFields;
      PORT = toString port;
      HEX = "true";
    } // (if usingApp then {
      GITHUB_APP_ID = githubAppId;
      GITHUB_APP_INSTALLATION_ID = githubAppInstallationId;
      GITHUB_APP_PRIVATE_KEY = "/secrets/${githubPrivateKeySecretKey}";
    } else {
      GITHUB_TOKEN = githubToken;
    });
    env = extraEnv;
    ${if secret != "" then "envFrom" else null} = [{ secretRef.name = secret; }];
    securityContext = { privileged = false; };
  }
    extraService
)
