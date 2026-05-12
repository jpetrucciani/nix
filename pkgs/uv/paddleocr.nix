# [paddleocr](https://github.com/PaddlePaddle/PaddleOCR) turns any PDF or image document into structured data
{ lib, uv-nix, ccache, version ? "3.5.0", lockHash ? "sha256-Xn8jaqJno42CpM+5/CtSZrihm9bpkYhWOjAjWz0lqE8=", includePin ? false }:
let
  name = "paddleocr";
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = name;

  lockUrl = "https://static.g7c.us/lock/uv/paddleocr/${version}.lock";

  postInstall = ''
    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath [ ccache ]}
  '';

  meta = {
    description = "turns any PDF or image document into structured data";
    homepage = "https://github.com/PaddlePaddle/PaddleOCR";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = name;
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
