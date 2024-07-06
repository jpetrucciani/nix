# [obligator](https://github.com/anderspitman/obligator) is an OIDC server designed for self-hosters
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule {
  pname = "obligator";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "anderspitman";
    repo = "obligator";
    rev = "37f75cc861f1bcd0dbf0f26a58e0f45bdae032ff";
    hash = "sha256-Di4nH/veqp1dTwJBavRENOI/NMsvhNtgN0QZ4OU4lfw=";
  };

  vendorHash = "sha256-snI3htyuBeeTOND8X5Wi+3WEW5xC+Y+C8jMfmiYAur4=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Simple and opinionated OpenID Connect server designed for self-hosters";
    homepage = "https://github.com/anderspitman/obligator";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "obligator";
  };
}
