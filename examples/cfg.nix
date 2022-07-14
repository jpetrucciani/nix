{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-07-13";
        url = "https://github.com/jpetrucciani/nix/archive/9176b8d8d4aff0188492b499d1f0e215cfc4b463.tar.gz";
        sha256 = "1c71x2gymfq2krq2rs18z1lq0jmd6l1baxzjk5shzqahxnsn4asq";
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
