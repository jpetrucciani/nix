{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-09-25";
        url = "https://github.com/jpetrucciani/nix/archive/0b15ea14815cc64d2abf0df643404401094084e6.tar.gz";
        sha256 = "0bk22jixq922i2sf1yds1z8ndikwfplyvc5r1l80jq60c48crp35";
      }
    )
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive
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
