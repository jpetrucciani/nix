{ lib, ... }:
{
  imports = [
    ./modules/conf/auto-update.nix
  ];
  _module.args.username = lib.mkDefault "jacobi";
  # conf.auto-update.enable = lib.mkDefault true;
}
