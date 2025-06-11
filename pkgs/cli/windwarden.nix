{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "windwarden";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "MagicSchoolAi";
    repo = "windwarden";
    rev = "v${version}";
    sha256 = "sha256-lUqP2/kzdz9DzTy+0MyFI7ryTwNdxlBbZkiFT2zHOaU=";
  };

  cargoHash = "sha256-s2pIi+jJtL8ilTxh+iHia6CWgqh/CfP0uf0jkF8btRA=";

  meta = with lib; {
    description = "A CLI tool for linting Tailwind";
    homepage = "https://github.com/MagicSchoolAi/windwarden";
    license = licenses.mit;
    maintainers = [ "benaduggan" ];
  };
}
