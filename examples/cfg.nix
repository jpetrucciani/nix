{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-09-30";
        url = "https://github.com/jpetrucciani/nix/archive/adcd7c18b9aed6ef84866866c0e75b27432f1bfa.tar.gz";
        sha256 = "071268mg4fd9zfvkam256641rmyp7rm9857ji4v8a7sqdlarijpa";
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
      (writeShellScriptBin "hms" ''
        nix-env -i -f ~/cfg.nix
      '')
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
