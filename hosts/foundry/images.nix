{ modulesPath, ... }:
{
  image.modules = {
    google-compute = import ./variants/google-compute.nix;
    google-compute-cuda = {
      imports = [
        (modulesPath + "/virtualisation/google-compute-image.nix")
        ./variants/google-compute.nix
        ./google-compute-cuda.nix
      ];
    };
    iso-installer = import ./variants/iso-installer.nix;
  };
}
