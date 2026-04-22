{
  self,
  lib,
  inputs,
  config,
  ...
}:
let
  polyModule =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        enableReleaseChecks = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";
        image = "${inputs.wallpapers}/22.png";
        imageScalingMode = "fill";
        icons = {
          enable = true;
          package = pkgs.vimix-icon-theme;
          light = "Ruby";
          dark = "Black";
        };
        fonts = rec {
          sizes = {
            applications = 12;
            desktop = 10;
            popups = 10;
            terminal = 12;
          };
          monospace = {
            package = pkgs.nerd-fonts.dejavu-sans-mono;
            name = "DejaVuSansM Nerd Font Mono";
          };
          sansSerif = monospace;
          serif = sansSerif;
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
        opacity = {
          applications = 0.9;
          desktop = 0.9;
          popups = 0.9;
          terminal = 0.85;
        };
        cursor = {
          package = pkgs.catppuccin-cursors.frappeRosewater;
          name = "catppuccin-frappe-rosewater-cursors";
          size = 16;
        };
      };
    };
in
{
  options.stylix = {
    colors = lib.mkOption {
      type = lib.types.raw;
      default =
        let
          fakeSystem = lib.nixosSystem {
            system = lib.head config.systems;
            modules = [
              inputs.stylix.nixosModules.stylix
              polyModule
            ];
          };
        in
        fakeSystem.config.lib.stylix.colors;
      readOnly = true;
    };
    module = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = polyModule;
      readOnly = true;
    };
  };

  config = {
    flake-file.inputs.stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.inputs.wallpapers = {
      url = "github:b0iizz/wallpapers";
      flake = false;
    };

    flake.modules = {

      nixos.base =
        { pkgs, ... }:
        {
          imports = [
            inputs.stylix.nixosModules.stylix
            (polyModule { inherit pkgs; })
          ];
          #stylix.homeManagerIntegration.autoImport = true;
        };

      homeManager.standalone =
        { pkgs, ... }:
        {
          imports = [
            inputs.stylix.homeModules.stylix
            (polyModule { inherit pkgs; })
          ];
        };

      nixvim.base = {
        imports =
          let
            fakeSystem = lib.nixosSystem {
              system = lib.head config.systems;
              modules = [
                inputs.stylix.nixosModules.stylix
                polyModule
              ];
            };
          in
          [
            fakeSystem.config.stylix.targets.nixvim.exportedModule
          ];
      };
    };
  };

}
