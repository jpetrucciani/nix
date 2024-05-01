{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage {
  pname = "borgo";
  version = "unstable-2023-09-11";

  src = fetchFromGitHub {
    owner = "borgo-lang";
    repo = "borgo";
    rev = "1d8d008192cb1be790422a5f2ce8c5c10213f4d8";
    hash = "sha256-4AjgTW2gFLUjr6XMNzzT6Pwt4f2E+ey1bCj8tx+rZS4=";
  };

  cargoHash = "sha256-vlXguCKfyicHEDZMWzNWvkIQJMYS3xVIShtLO5XpK0A=";

  postInstall = ''
    mv $out/bin/compiler $out/bin/borgo
  '';

  meta = with lib; {
    description = "Borgo is a statically typed language that compiles to Go";
    homepage = "https://github.com/borgo-lang/borgo";
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "borgo";
  };
}
