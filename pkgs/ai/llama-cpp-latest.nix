{ config
, cudaSupport ? config.cudaSupport
, fetchFromGitHub
, llama-cpp
, nodejs_24
, refresh_llama-cpp_latest
, stdenv
}:
let
  version = "12233";
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

  postPatch = (old.postPatch or "") + ''
    # The dummy-model generator bypasses the common argument parser that loads backends.
    substituteInPlace tests/test-llama-archs.cpp \
      --replace-fail '    common_init();' '    common_init();
        ggml_backend_load_all();'
  '';

  cmakeFlags = if stdenv.hostPlatform.isDarwin then old.cmakeFlags ++ [ "-DLLAMA_BUILD_NUMBER=1" ] else old.cmakeFlags;

  disabledTests = (old.disabledTests or [ ]) ++ [
    # Otherwise CTest re-adds the excluded download fixture for this test.
    "test-state-restore-fragmented"
  ];

  passthru = (old.passthru or { }) // {
    updateScript = refresh_llama-cpp_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
