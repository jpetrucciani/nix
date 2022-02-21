_:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/b7f28d21-0d21-4c9e-9aa5-4c8248a0fa09";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/494B-A937";
      fsType = "vfat";
    };

  swapDevices = [ ];

  virtualisation.hypervGuest.enable = true;
}
