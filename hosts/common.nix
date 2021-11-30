{ config, pkgs, ... }:
let
  home-manager = fetchTarball "https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz";
  jacobi = import ../home.nix;
in
{
  inherit jacobi home-manager;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      max-jobs = auto
      extra-experimental-features = nix-command flakes
    '';
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
