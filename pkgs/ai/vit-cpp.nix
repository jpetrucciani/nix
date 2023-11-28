{ lib
, stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  pname = "vit-cpp";
  version = "1.0.0-alpha";

  src = fetchFromGitHub {
    owner = "staghado";
    repo = "vit.cpp";
    rev = "refs/tags/v${version}";
    hash = "sha256-ey85b0/6Rxh1PyKhQBUdCHtUmQMcP8GbIODuUIq9pUI=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
  ];

  postInstall = ''
    mkdir -p $out/bin
    mv ./bin/* $out/bin/.
  '';

  meta = with lib; {
    description = "Inference Vision Transformer (ViT) in plain C/C++ with ggml";
    homepage = "https://github.com/staghado/vit.cpp";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "vit";
    platforms = platforms.all;
  };
}
