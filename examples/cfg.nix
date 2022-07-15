{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-07-14";
        url = "https://github.com/jpetrucciani/nix/archive/806a1827f07c3775e5fcf07cf489db80b41105c3.tar.gz";
        sha256 = "07gh7mxhaz2sgf80lwq584wqxav3iar3jxm0rp14cmg8nim8c290";
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
