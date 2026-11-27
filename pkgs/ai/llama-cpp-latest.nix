{ config
, cudaPackages
, cudaSupport ? config.cudaSupport
, fetchFromGitHub
, lib
, llama-cpp
, nodejs_24
, refresh_llama-cpp_latest
}:
let
  version = "12815";
in
(llama-cpp.override {
  inherit cudaPackages cudaSupport;
  nodejs_latest = nodejs_24;
}).overrideAttrs (old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    hash = "sha256-8KLACn0QXUAndRjKPVAm5Fq8yACWRwHRZehK7NLyIKQ=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  npmRoot = "ui/apps/chat";
  npmDepsHash = "sha256-ogXf1Ay3TnCLbkMcXVHdZhxL3PzJdlMT+RyXpcy/Qrw=";

  # GGML loads NVML from the NVIDIA driver at runtime.
  buildInputs = old.buildInputs ++ lib.optional cudaSupport cudaPackages.cuda_nvml_dev.include;

  postPatch = (old.postPatch or "") + ''
    # The dummy-model generator bypasses the common argument parser that loads backends.
    substituteInPlace tests/test-llama-archs.cpp \
      --replace-fail '    common_init();' '    common_init();
        ggml_backend_load_all();'
  '';

  preConfigure = ''
    cmakeFlagsArray+=(
      "-DLLAMA_BUILD_NUMBER:STRING=${version}"
      "-DLLAMA_BUILD_COMMIT:STRING=$(cat COMMIT)"
    )
    pushd "$npmRoot"
    LLAMA_BUILD_NUMBER=${version} npm run build
    popd
  '';

  passthru = (old.passthru or { }) // {
    updateScript = refresh_llama-cpp_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
