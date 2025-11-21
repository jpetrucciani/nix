{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };
    extraModulePackages = [ ];
    supportedFilesystems = [ "nfs" "zfs" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/628eb25a-ec4f-4f73-84a7-8a96c335d47a";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
  };

  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
