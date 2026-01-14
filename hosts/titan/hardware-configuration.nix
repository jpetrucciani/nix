{ config, lib, modulesPath, pkgs, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };
    kernelModules = [ "kvm-amd" "nvidia" ];
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [ ];
    supportedFilesystems = [ "nfs" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5f99f1f8-1b07-4e16-9ce5-8eaa984bbe7f";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D097-E85E";
    fsType = "vfat";
  };
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
