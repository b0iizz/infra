{
  self,
  lib,
  inputs,
  ...
}:
{

  flake-file.inputs.disko = {
    url = "github:nix-community/disko/latest";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.host-pc =
    {
      config,
      configurationName,
      pkgs,
      ...
    }:
    {
      assertions = [
        {
          assertion = config ? disko;
          message = "PCs must have a disko configuration";
        }
        {
          assertion = config.hardware.facter.enable;
          message = "PCs must use NixOS facter";
        }
      ];

      imports = [ (inputs.disko.nixosModules.disko or { }) ];

      installer.arguments.check = { };
      installer.supportedSystems = lib.singleton pkgs.stdenv.hostPlatform.system;
      installer.installStep = pkgs: ''
        if [[  ''${${config.installer.arguments.check.variable}} -eq 1 ]]; then
          sudo ${lib.getExe pkgs.nix} --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --root-mountpoint /mnt --flake '${self}#${configurationName}' --dry-run
        else
          sudo ${lib.getExe pkgs.nix} --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --root-mountpoint /mnt --flake '${self}#${configurationName}'
          sudo mkdir -p /mnt/etc/ssh
          setup_host_keys '/mnt${config.installer.hostKeyLocation}' 600 600 0
          sudo mkdir -p /mnt/etc/nixos
          sudo cp -r '${self}' /mnt/etc/nixos
          sudo nixos-install --root /mnt --no-root-password --show-trace --flake '${self}#${configurationName}'
        fi
      '';
    };
}
