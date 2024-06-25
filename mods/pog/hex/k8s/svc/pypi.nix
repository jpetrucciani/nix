{ hex, ... }:
{ s3Bucket
, s3Prefix ? "pypi/"
, s3Region ? "us-east-2"
, htpasswdEnabled ? true
, htpasswdEnvVar ? "$HTPASSWD"
, name ? "pypi"
, namespace ? "default"
, image_registry ? "ghcr.io/jpetrucciani"
, image_base ? "pypi"
, image_tag ? "2024-06-25"
, image ? "${image_registry}/${image_base}:${image_tag}"
, replicas ? 2
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, port ? 10000
, secretName ? "pypi-secret"
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
, labels ? {
    inherit name;
    tier = "infra";
  }
, extraService ? { } # escape hatch to inject other service spec
}:
let
  volumes = [ hex.k8s.services.components.volumes.tmp ];
  htpasswd = if htpasswdEnabled then ''-P <(echo ${htpasswdEnvVar})'' else "";
in
hex.k8s.services.build ({
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge;
  command = "/bin/bash";
  args = [
    "-c"
    ''pypi-server run --backend=s3 -p $PORT ${htpasswd}''
  ];
  envAttrs = {
    AWS_DEFAULT_REGION = s3Region;
    PYPISERVER_BACKEND_S3_BUCKET = s3Bucket;
    PYPISERVER_BACKEND_S3_PREFIX = s3Prefix;
    PORT = toString port;
    HEX = "true";
  };
  envFrom = [
    { secretRef.name = secretName; }
  ];
  env = extraEnv;
  securityContext = { privileged = false; };
} // extraService)
