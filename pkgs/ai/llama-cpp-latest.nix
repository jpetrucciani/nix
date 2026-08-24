{ config
, cudaSupport ? config.cudaSupport
, fetchFromGitHub
, llama-cpp
, refresh_llama-cpp_latest
, stdenv
}:
let
  version = "10430";
in
(llama-cpp.override { inherit cudaSupport; }).overrideAttrs (old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    hash = "sha256-jhMnyPKgHZfDAJUhjaZt38Hiflf9MnFb5xZutkJ/cTk=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  npmRoot = "tools/ui";
  npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";

  cmakeFlags = if stdenv.hostPlatform.isDarwin then old.cmakeFlags ++ [ "-DLLAMA_BUILD_NUMBER=1" ] else old.cmakeFlags;

  passthru = (old.passthru or { }) // {
    updateScript = refresh_llama-cpp_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
