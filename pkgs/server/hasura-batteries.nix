{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "hasura-batteries";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "RocketsGraphQL";
    repo = "hasura-batteries";
    rev = "v${version}";
    hash = "sha256-BRxsJ35imucFGt0t39i9kxbDc38AbR/XTIps2rKf248=";
  };

  vendorHash = "sha256-OdYmaDK/XY1MNXoEl9HKYg20KukE7auHmilmTjIGMYc=";
  doCheck = false;

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "";
    homepage = "https://github.com/RocketsGraphQL/hasura-batteries";
    # license = licenses.unfree;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "hasura-batteries";
  };
}
