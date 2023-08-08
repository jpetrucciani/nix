{ stdenvNoCC, fetchurl, autoPatchelfHook, lib }:
let
  dists = {
    aarch64-darwin = {
      arch = "arm";
      short = "darwin";
      sha256 = "0s4mcjr7qqs5ry65gyil4rama48yv8rqqif875y73bfcc0mjzqk4";
    };
    aarch64-linux = {
      arch = "arm";
      short = "linux";
      sha256 = "13l5p1nlf33z96fkh1q9fnpis0xdgbpqdm0v6ngfnjwbqpcfg9sw";
    };
    x86_64-darwin = {
      arch = "x86_64";
      short = "darwin";
      sha256 = "1zaxhhfc47jdqlkzjgi3mvihxpwlx930lrwnmmscz5m6fjl2dfg7";
    };
    x86_64-linux = {
      arch = "x86_64";
      short = "Linux";
      sha256 = "08pjpkv91pjpk21y2c8bq2ygpk1bpz5nnxc3sy0l5wrpr05mibxb";
    };
  };
  dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "gke-gcloud-auth-plugin";
  version = "0.5.3";
  ts = "20230509142714";
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
  meta = { };
}
