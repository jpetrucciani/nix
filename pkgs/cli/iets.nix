{ flake, stdenv }:
flake.inputs.iets.packages.${stdenv.hostPlatform.system}.default
