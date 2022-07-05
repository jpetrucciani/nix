{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-07-05";
        url = "https://github.com/jpetrucciani/nix/archive/63eeb0aa2c512f2850630ee3c4483a0ce2b6c373.tar.gz";
        sha256 = "0gm9bcracqim3zwly0wi29cj6fnixdj3yg4mx4hjzrglcmj2kq94";
      }
    )
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive_5
      comma
      cowsay
      curl
      delta
      dyff
      figlet
      git
      gron
      jq
      just
      nodePackages.prettier
      scc
      shfmt
      yq-go
    ];
    nix = [
      nixpkgs-fmt
      nixup
    ];
    python = [
      (python310.withPackages (p: with p; [
        bandit
        black
        flake8
        mypy
        pylint
        requests
      ]))
    ];
  };

  env = jacobi.enviro {
    inherit name tools;
  };
in
env
