{ self, inputs, ... }:
{

  flake.nixosModules.prometheusConfiguration =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      /*
         fileSystems."/" = {
           device = "/dev/disk/by-uuid/4fc2fb06-5449-4091-b8c7-867bfd316362";
           fsType = "ext4";
         };

         fileSystems."/boot" = {
           device = "/dev/disk/by-uuid/C515-6E24";
           fsType = "vfat";
           options = [
             "fmask=0077"
             "dmask=0077"
           ];
         };

         swapDevices = [
           { device = "/dev/disk/by-uuid/b609aac0-15a9-4473-b237-be540d370cc1"; }
         ];
      */
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
