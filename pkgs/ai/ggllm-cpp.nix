{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub, cmake, common-updater-scripts, coreutils, curl, jq, nix, nix-prefetch-github, writeScript, cudatoolkit, ggllm-cpp, cuda ? false }:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  version = "master-3e4c021";
  owner = "cmp-nct";
  repo = "ggllm.cpp";
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/${version}";
    hash = "sha256-kf+xhwIdufHHD7o1lHvYKD1e/XSZCzb9fa7I5hu3Oug=";
  };

  postPatch =
    if isM1 then ''
      substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/ggml-metal.metal\";"
    '' else "";

  cmakeFlags = [
    "-DLLAMA_BUILD_SERVER=ON"
  ] ++ (optionals isM1 [
    "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
    "-DLLAMA_METAL=ON"
  ]) ++ (optionals cuda [
    "-DLLAMA_CUBLAS=ON"
  ]);
  installPhase = ''
    mkdir -p $out/bin
    cp ../ggml-metal.metal $out/.
    mv ./bin/main $out/bin/ggllm
    mv ./bin/perplexity $out/bin/ggllm-perplexity
    mv ./bin/quantize $out/bin/ggllm-quantize
    mv ./bin/quantize-stats $out/bin/ggllm-quantize-stats
    mv ./bin/server $out/bin/ggllm-server
  '';
  buildInputs = osSpecific;
  nativeBuildInputs = [ cmake ] ++ (optionals cuda [ cudatoolkit ]);

  passthru.updateScript =
    let
      pkg = "ggllm-cpp";
      _jq = lib.getExe jq;
      _curl = lib.getExe curl;
      _prefetch = lib.getExe nix-prefetch-github;
      _tr = "${coreutils}/bin/tr";
      _update = "${common-updater-scripts}/bin/update-source-version";
    in
    writeScript "ggllm-cpp-update-script" ''
      current_version="$(${nix}/bin/nix-instantiate --eval -E "with import ./. {}; lib.getVersion ${pkg}" | ${_tr} -d '"')"
      latest_version="$(${_curl} -s https://api.github.com/repos/${owner}/${repo}/releases/latest | ${_jq} --raw-output .tag_name)"
      latest_sha="$(${_prefetch} --rev "refs/tags/$latest_version" ${owner} ${repo} | ${_jq} --raw-output .sha256)"
      if [ ! "$current_version" = "$latest_version" ]; then
        ${_update} ${pkg} "$latest_version" "$latest_sha"
      else
        echo "${pkg} is already up to date as '$current_version'"
      fi
    '';
  passthru.cuda = ggllm-cpp.override { cuda = true; };

  meta = with lib; {
    description = "Falcon LLM ggml framework with CPU and GPU support";
    homepage = "https://github.com/cmp-nct/ggllm.cpp";
    mainProgram = "ggllm";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}