# [obligator](https://github.com/lastlogin-net/obligator) is an OIDC server designed for self-hosters
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule {
  pname = "obligator";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "anderspitman";
    repo = "obligator";
    rev = "623276f2ff6a390865cce0627f0ac3c4e584b062";
    hash = "sha256-zNR27CthwAf9QieYe7Ei/VZ8Bn30Sxi3L0BR4zcqmqM=";
  };

  vendorHash = "sha256-snI3htyuBeeTOND8X5Wi+3WEW5xC+Y+C8jMfmiYAur4=";

  env.CGO_ENABLED = 1;
  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Simple and opinionated OpenID Connect server designed for self-hosters";
    homepage = "https://github.com/lastlogin-net/obligator";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "obligator";
  };
}
