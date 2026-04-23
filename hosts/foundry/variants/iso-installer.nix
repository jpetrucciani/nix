{ lib, ... }:
{
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce true;
    PermitRootLogin = lib.mkForce "yes";
  };
}
