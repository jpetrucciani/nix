{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-07-03";
        url = "https://github.com/jpetrucciani/nix/archive/3b5d3941ba0e9edc059b75493c9a475c2dd89919.tar.gz";
        sha256 = "0gp277cks2asgawldlmnpi53i9m6ky6x7659186zkqqk8yikadad";
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
