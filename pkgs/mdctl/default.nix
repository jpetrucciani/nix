{ pkgs ? import <nixpkgs> {
    inherit system;
  }
, system ? builtins.currentSystem
, nodejs ? pkgs."nodejs-14_x"
}:

let
  nodeEnv = import ./node-env.nix {
    inherit (pkgs) stdenv lib python2 runCommand writeTextFile;
    inherit pkgs nodejs;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
  osSpecific = if pkgs.stdenv.isDarwin then [ pkgs.darwin.apple_sdk.frameworks.Security pkgs.darwin.apple_sdk.frameworks.AppKit ] else [ ];
in
import ./node-packages.nix {
  inherit (pkgs) fetchurl nix-gitignore stdenv lib fetchgit;
  inherit nodeEnv;
  globalBuildInputs = with pkgs; [
    gcc
    glib
    gnumake
    libsecret
    pkg-config
    nodePackages.node-pre-gyp
    (lib.flatten osSpecific)
  ];
}
