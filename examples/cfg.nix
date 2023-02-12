{ jacobi ? import
    (fetchTarball {
      name = "jpetrucciani-2023-02-11";
      url = "https://github.com/jpetrucciani/nix/archive/6d7df8d392abd9333e0e48757702e828ee2012d7.tar.gz";
      sha256 = "019rdq1rwh52r2gf06hhy7ldh2k0wa0sdbqmrspmn4v8g96vz98i";
    })
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive
      coreutils
      cowsay
      curl
      delta
      direnv
      dyff
      figlet
      git
      gron
      jq
      just
      moreutils
      nodePackages.prettier
      scc
      yq-go
      hax.comma
      (writeShellScriptBin "hms" ''
        nix-env -i -f ~/cfg.nix
      '')
    ];
    k8s = [
      kubectl
      kubectx
      gke-gcloud-auth-plugin
    ];
    nix = [
      nixpkgs-fmt
      nixup
      nix-direnv
    ];
    python = [
      ruff
      (python310.withPackages (p: with p; [
        black
        mypy
        requests
      ]))
    ];
  };

  env = let paths = jacobi._toolset tools; in
    jacobi.buildEnv {
      inherit name paths;
      buildInputs = paths;
    };
in
env
