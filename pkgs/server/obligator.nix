{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "obligator";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "anderspitman";
    repo = "obligator";
    rev = version;
    hash = "sha256-ESuBYK7kcVR3PjSqswnnWG/VHEfkpgemkXp490TFX5s=";
  };

  vendorHash = "sha256-pEz4odZyqlWt11DTlBM5kWbcBbEIW2KoYlymaodVI/M=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Simple and opinionated OpenID Connect server designed for self-hosters";
    homepage = "https://github.com/anderspitman/obligator";
    license = licenses.unfree; # FIXME: nix-init did not found a license
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "obligator";
  };
}
