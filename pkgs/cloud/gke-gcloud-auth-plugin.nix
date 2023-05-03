{ stdenvNoCC, fetchurl, autoPatchelfHook, lib }:
let
  dists = {
    aarch64-darwin = {
      arch = "arm";
      short = "darwin";
      sha256 = "0nf1d88b2c2aqrmcb2hrw9g5gxvhxj0m39mbnz7k2xw6gcl2brbk";
    };
    aarch64-linux = {
      arch = "arm";
      short = "linux";
      sha256 = "18x1rn8sidcpnx1ipxi9gl6hpqhsp8zf8gjc20nyb8rjjk2pdh14";
    };
    x86_64-darwin = {
      arch = "x86_64";
      short = "darwin";
      sha256 = "1239rmp753vp6lb6fdq7kxa19x2qn7a11zb4j5dd5nwx6rxlhp4m";
    };
    x86_64-linux = {
      arch = "x86_64";
      short = "Linux";
      sha256 = "1ibmd3fjmwvm0dc1vmirf656hznh6sdak8z67fxq3ipbgmjmn3bz";
    };
  };
  dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "gke-gcloud-auth-plugin";
  version = "0.5.2";
  ts = "20230317195124";
in
stdenvNoCC.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    inherit (dist) sha256;
    url = "https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-gke-gcloud-auth-plugin-${dist.short}-${dist.arch}-${ts}.tar.gz";
  };

  strictDeps = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    tar xzvf ${src}
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ./bin/gke-gcloud-auth-plugin $out/bin/gke-gcloud-auth-plugin
  '';
}
