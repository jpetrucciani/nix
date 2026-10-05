{ config
, cudaSupport ? config.cudaSupport
, fetchFromGitHub
, llama-cpp
, nodejs_24
, refresh_llama-cpp_latest
, stdenv
}:
let
  version = "11430";
in
(llama-cpp.override {
  inherit cudaSupport;
  nodejs_latest = nodejs_24;
}).overrideAttrs (old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    hash = "sha256-p2pShof7VpGZSHhezWvIL44Ou9CTK8e1OT3iBNdwU+I=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  npmRoot = "tools/ui";
  npmDepsHash = "sha256-a17M+L3nLdRnN6WMB6imPFmwqG2g8uv+gwN0XTAUrf8=";

  cmakeFlags = if stdenv.hostPlatform.isDarwin then old.cmakeFlags ++ [ "-DLLAMA_BUILD_NUMBER=1" ] else old.cmakeFlags;

  passthru = (old.passthru or { }) // {
    updateScript = refresh_llama-cpp_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
