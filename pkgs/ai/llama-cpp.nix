{ lib
, system
, symlinkJoin
, darwin
, stdenv
, clangStdenv
, fetchFromGitHub
, cmake
, common-updater-scripts
, coreutils
, curl
, jq
, nix
, nix-prefetch-github
, ninja
, writeScript
, llama-cpp
, cudatoolkit
, clblas
, clblast
, ocl-icd
, blas
, opencl-headers
, openmpi
, pkg-config
, cuda ? false
, opencl ? false
}:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [
      clblas
      clblast
      ocl-icd
      opencl-headers
      blas
    ];

  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ] ++ lib.optionals (lib.versionOlder cudatoolkit.version "11") [
      "${cudatoolkit}/targets/${system}"
    ];
  };
  version = "b2359";
  owner = "ggerganov";
  repo = "llama.cpp";
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/${version}";
    hash = "sha256-7Zu1Hww6dfPfIlV4ywB03XQdSFC3KcBO05t5ytT0KrA=";
  };

  postPatch =
    if isM1 then ''
      substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/ggml-metal.metal\";"
    '' else "";

  cmakeFlags = [
    "-DLLAMA_BUILD_SERVER=ON"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ] ++ (optionals isM1 [
    "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
    "-DLLAMA_METAL=ON"
  ]) ++ (optionals cuda [
    "-DLLAMA_CUBLAS=ON"
  ]) ++ (optionals (!isM1) [
    "-DLLAMA_BLAS=ON"
    (if opencl then "-DLLAMA_CLBLAST=ON" else "-DLLAMA_BLAS_VENDOR=OpenBLAS")
  ]);
  installPhase = ''
    mkdir -p $out/bin
    cp ../ggml-metal.metal $out/.
    mv ./bin/main $out/bin/llama
    mv ./bin/perplexity $out/bin/llama-perplexity
    mv ./bin/quantize $out/bin/llama-quantize
    mv ./bin/quantize-stats $out/bin/llama-quantize-stats
    mv ./bin/server $out/bin/llama-server
    mv ./bin/llava-cli $out/bin/llava
  '';
  buildInputs = [ openmpi ] ++ osSpecific;
  nativeBuildInputs = [ cmake ninja pkg-config ] ++ (optionals cuda [ cudatoolkit_joined ]);

  passthru.updateScript =
    let
      pkg = "llama-cpp";
      _jq = lib.getExe jq;
      _curl = lib.getExe curl;
      _prefetch = lib.getExe nix-prefetch-github;
      _tr = "${coreutils}/bin/tr";
      _update = "${common-updater-scripts}/bin/update-source-version";
    in
    writeScript "llama-cpp-update-script" ''
      current_version="$(${nix}/bin/nix-instantiate --eval -E "with import ./. {}; lib.getVersion ${pkg}" | ${_tr} -d '"')"
      latest_version="$(${_curl} -s https://api.github.com/repos/${owner}/${repo}/releases/latest | ${_jq} --raw-output .tag_name)"
      latest_sha="$(${_prefetch} --rev "refs/tags/$latest_version" ${owner} ${repo} | ${_jq} --raw-output .sha256)"
      if [ ! "$current_version" = "$latest_version" ]; then
        ${_update} ${pkg} "$latest_version" "$latest_sha"
      else
        echo "${pkg} is already up to date as '$current_version'"
      fi
    '';
  passthru.cuda = llama-cpp.override { cuda = true; };
  passthru.opencl = llama-cpp.override { opencl = true; };

  meta = with lib; {
    description = "Port of Facebook's LLaMA model in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    mainProgram = "llama";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
