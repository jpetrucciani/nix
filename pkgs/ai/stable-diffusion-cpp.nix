# [`stable-diffusion.cpp`](https://github.com/leejet/stable-diffusion.cpp) is a port of stable-diffusion model inference in C/C++
{ lib
, symlinkJoin
, cmake
, stdenv
, stable-diffusion-cpp
, clangStdenv
, cudatoolkit
, rocmPackages
, fetchFromGitHub
, cuda ? false
, rocm ? false
, flashattn ? true
}:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ];
  };
  version = "master-e1384de";
  owner = "leejet";
  repo = "stable-diffusion.cpp";
  _CMAKE_ARGS = (optionals isM1 [ "-DSD_METAL=on" ])
    ++ (optionals cuda [ "-DSD_CUBLAS=on" ])
    ++ (optionals flashattn [ "-DSD_FLASH_ATTN=on" ])
    ++ (optionals rocm [ "-DSD_HIPBLAS=on" ]);
in
clangStdenv.mkDerivation {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/${version}";
    hash = "sha256-GWl1CAIrAPF6rLmJG/cZbxrh3HGxg/qK6/OvyAShYtM=";
    fetchSubmodules = true;
  };

  CMAKE_ARGS = builtins.concatStringsSep " " _CMAKE_ARGS;

  nativeBuildInputs = [ cmake ]
    ++ (optionals cuda [ cudatoolkit_joined ])
    ++ (optionals rocm (with rocmPackages; [ clr hipblas rocblas ]));

  passthru = {
    cuda = stable-diffusion-cpp.override { cuda = true; };
    rocm = stable-diffusion-cpp.override { rocm = true; };
  };

  meta = with lib; {
    description = "Stable Diffusion in pure C/C++";
    homepage = "https://github.com/leejet/stable-diffusion.cpp";
    mainProgram = "sd";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
