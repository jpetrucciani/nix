# [10mb.video](https://github.com/ugjka/10mb.video) is a tool to help hyper-compress videos!
{ lib
, buildGoModule
, fetchFromGitHub
, ffmpeg
, fdk-aac-encoder
, makeWrapper
}:
let
  runtimeDeps = lib.makeBinPath [
    ffmpeg
    fdk-aac-encoder
  ];
in
buildGoModule {
  pname = "10mb-video";
  version = "unstable-2024-11-19";

  src = fetchFromGitHub {
    owner = "ugjka";
    repo = "10mb.video";
    rev = "99b795adc14287632c40ddc48824a500d92e4cd9";
    hash = "sha256-xqKuH3Sm+wF6PwKNOC/YPh9b786PxKDiFNR13SydgT8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  postFixup = ''
    wrapProgram $out/bin/10mb.video --prefix PATH : ${runtimeDeps}
  '';

  meta = {
    description = "Fit a video into a 10mb file (Discord nitro pls?)";
    homepage = "https://github.com/ugjka/10mb.video";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "10mb.video";
  };
}
