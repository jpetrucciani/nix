final: prev:
with prev;
rec {
  pynix =
    pog {
      name = "pynix";
      description = "pynixify pip dependencies in an easy way!";
      flags = [
        {
          name = "pynixify";
          short = "x";
          description = "the rev or branch of pynixify to use";
          default = "main";
        }
        {
          name = "python";
          description = "the version of python to use from nixpkgs";
          default = "python311";
        }
      ];
      arguments = [
        { name = "pip_package"; }
      ];
      script = ''
        export NIX_PATH="nixpkgs=${prev.path}"
        pip_package="$1"
        pynixify_tarball="https://github.com/cript0nauta/pynixify/archive/$pynixify.tar.gz"
        nixpkgs_tarball="https://github.com/NixOS/nixpkgs/archive/$nixpkgs.tar.gz"
        nix shell -f "$pynixify_tarball" --argstr python "$python" -c pynixify --nixpkgs "$nixpkgs_tarball" "$pip_package"
      '';
    };

  python_pog_scripts = [
    pynix
  ];
}
