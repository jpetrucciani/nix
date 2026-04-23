{ lib, ... }:
{
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
}
