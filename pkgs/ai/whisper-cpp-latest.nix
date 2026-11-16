{ config
, cudaSupport ? config.cudaSupport
, fetchFromGitHub
, lib
, refresh_whisper-cpp_latest
, whisper-cpp
}:
let
  version = "1.9.5";
in
(whisper-cpp.override { inherit cudaSupport; }).overrideAttrs (old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "whisper.cpp";
    tag = "v${version}";
    hash = "sha256-Qqqpt+pvCQwSbyaBr1bdb7q+3LbELTcloHdiSikGPc4=";
  };

  postPatch = (old.postPatch or "") + ''
    substituteInPlace examples/CMakeLists.txt \
      --replace-fail "        add_subdirectory(talk-llama)" ""
  '';

  cmakeFlags = old.cmakeFlags ++ [
    (lib.cmakeBool "WHISPER_BUILD_IS_DEV" false)
  ];

  passthru = (old.passthru or { }) // {
    updateScript = refresh_whisper-cpp_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
