# [cronv](https://github.com/takumakanari/cronv) is a visualizer for crontab entries
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cronv";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "takumakanari";
    repo = "cronv";
    rev = version;
    hash = "sha256-P11XA4NGX00fm0Ep72g1g3mzXgvs+w/FhmOLNaKmqn4=";
  };

  vendorHash = "sha256-CtwFJOedpWZsmu5qKOUYupBJbRjgDenJtoyKaM3Pksw=";

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "A visualizer for CRONTAB";
    homepage = "https://github.com/takumakanari/cronv";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "cronv";
  };
}
