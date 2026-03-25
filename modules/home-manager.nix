{ lib, inputs, ... }@toplevel:
{

  flake-file.inputs.home-manager.url = "github:nix-community/home-manager";
  flake-file.inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  flake.modules.homeManager.base = {
    home.stateVersion = lib.mkDefault "26.05";
  };

  flake.modules.nixos.base =
    { lib, config, ... }:
    let
      cfg = config.settings.home-manager;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager or {
          options.home-manager = lib.mkOption { type = lib.types.raw; };
        }
      ];

      options.settings.home-manager.enable = lib.mkEnableOption "home-manager" // {
        default = true;
      };
      config = lib.mkIf (cfg.enable) {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = false;
          backupFileExtension = "bak";
          sharedModules = [ toplevel.config.flake.modules.homeManager.base ];
        };
      };
    };
}
