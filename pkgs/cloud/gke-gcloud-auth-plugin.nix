# gke-gcloud-auth-plugin is a required plugin for using kubectl with Google's GKE on GCP
{ stdenvNoCC, fetchurl, autoPatchelfHook, lib }:
let
  dists = {
    aarch64-darwin = {
      arch = "arm";
      short = "darwin";
      sha256 = "1aafygx5a0c5xc9c8ypqb4331zlhbzznszhaj50iin8hkf043dr7";
    };
    aarch64-linux = {
      arch = "arm";
      short = "linux";
      sha256 = "1lslvdwxgigywqic0bw3by9sc9prq15g6zwpgpfll8m12smhq25a";
    };
    x86_64-darwin = {
      arch = "x86_64";
      short = "darwin";
      sha256 = "0jyqm2n157d402izc8bfn8xdp3rissfc3zzg1f5yk7sw2jg0vvsd";
    };
    x86_64-linux = {
      arch = "x86_64";
      short = "Linux";
      sha256 = "13z4jvfn5qr024hannklvac0mjj38dyjnaqzpwv286ca1a4c5v4m";
    };
  };
  dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "gke-gcloud-auth-plugin";
  version = "0.5.9";
  ts = "20240628141907";
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
