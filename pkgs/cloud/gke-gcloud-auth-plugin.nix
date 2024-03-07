{ stdenvNoCC, fetchurl, autoPatchelfHook, lib }:
let
  dists = {
    aarch64-darwin = {
      arch = "arm";
      short = "darwin";
      sha256 = "0330j7g1brwh3wlaid0zjh5nrssn2463a17zvg6ni0q8y78432bl";
    };
    aarch64-linux = {
      arch = "arm";
      short = "linux";
      sha256 = "0cknn833n0kvz3kap79n31zcxfd0jggxhc57hd5aai2zmvggnfds";
    };
    x86_64-darwin = {
      arch = "x86_64";
      short = "darwin";
      sha256 = "1dj0ih7666isjfahcz2alp8grjnvgjc76glv0pwycmxn3bxbks47";
    };
    x86_64-linux = {
      arch = "x86_64";
      short = "Linux";
      sha256 = "16pc1320a66s8cfv7r1j1m2q05dda1d332ns3dvf5f5hpfdkbnfq";
    };
  };
  dist = dists.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  pname = "gke-gcloud-auth-plugin";
  version = "0.5.6";
  ts = "20230915145114";
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
