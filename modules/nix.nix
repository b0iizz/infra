{ lib, self, ... }:
{
  flake.modules.nixos.base = {
    nix.settings = {
      trusted-users = [ "@wheel" ];
      experimental-features = lib.mkDefault [
        "nix-command"
        "flakes"
      ];
    };

    system.activationScripts.current-flake = lib.stringAfter [ "specialfs" ] ''
      ln -sfn ${self} /run/current-flake
    '';
  };
}
