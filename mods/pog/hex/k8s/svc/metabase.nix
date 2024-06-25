{ hex, ... }:
{ domain
, name ? "metabase"
, namespace ? "default"
, image ? "${image_base}:${image_tag}"
, image_base ? "metabase/metabase"
, image_tag ? "v0.50.6"
, replicas ? 1
, cpuRequest ? "0.5"
, cpuLimit ? "1.0"
, memoryRequest ? "1024Mi"
, memoryLimit ? "4096Mi"
, autoscale ? false
, port ? 3000
, dbName ? "metabase"
, dbUser ? "metabase"
, dbHost ? ""
, dbPort ? 5432
, dbPassSecret ? "metabase-secret"
, dbPassSecretKey ? "db-password"
, labels ? {
    app = "metabase";
    tier = "api";
  }
, extraEnv ? [
    {
      name = "MB_DB_PASS";
      valueFrom = {
        secretKeyRef = {
          key = dbPassSecretKey;
          name = dbPassSecret;
        };
      };
    }
  ]
, enableEmbedding ? true
, enableHttpsRedirect ? true
, googleAuthDomain ? ""
, googleAuthClientId ? ""
, extraService ? { } # escape hatch to inject other service spec
}:
let
  inherit (hex) boolToString ifSet;
  probe = {
    httpGet = {
      inherit port;
      path = "/api/health";
    };
    failureThreshold = 3;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    successThreshold = 1;
    timeoutSeconds = 4;
  };
in
hex.k8s.services.build ({
  inherit name namespace port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale labels;
  softAntiAffinity = true;
  env = extraEnv;
  envAttrs = {
    HEX = "true";
    MB_SITE_URL = domain;
    MB_DB_HOST = dbHost;
    MB_DB_DBNAME = dbName;
    MB_DB_PORT = toString dbPort;
    MB_DB_TYPE = "postgres";
    MB_DB_USER = dbUser;
    MB_ENABLE_EMBEDDING = boolToString enableEmbedding;
    MB_REDIRECT_ALL_REQUESTS_TO_HTTPS = boolToString enableHttpsRedirect;
    ${ifSet googleAuthDomain "MB_GOOGLE_AUTH_AUTO_CREATE_ACCOUNTS_DOMAIN"} = googleAuthDomain;
    ${ifSet googleAuthClientId "MB_GOOGLE_AUTH_CLIENT_ID"} = googleAuthClientId;
  };
  volumes = [ hex.k8s.services.components.volumes.tmp ];
  livenessProbe = probe;
  readinessProbe = probe;
  securityContext = { privileged = false; };
} // extraService)
