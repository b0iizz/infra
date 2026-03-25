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
        image = "${self}/wallpapers/22.png";
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
            package = pkgs.dejavu_fonts;
            name = "DejaVu Sans Mono";
          };
          sansSerif = monospace;
          serif = sansSerif;
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
        cursor = {
          package = pkgs.catppuccin-cursors.frappeRosewater;
          name = "Catppuccin-Frappe-Rosewater-Cursors";
          size = 16;
        };
      };
    };
in
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules = {

    nixos.base = lib.mkIf (inputs ? stylix) (
      { pkgs, ... }:
      {
        imports = [
          inputs.stylix.nixosModules.stylix
          (polyModule { inherit pkgs; })
        ];
        #stylix.homeManagerIntegration.autoImport = true;
      }
    );

    homeManager.standalone = lib.mkIf (inputs ? stylix) (
      { pkgs, ... }:
      {
        imports = [
          inputs.stylix.homeModules.stylix
          (polyModule { inherit pkgs; })
        ];
      }
    );

    nixvim.base = lib.mkIf (inputs ? stylix) (
      let
        fakeSystem = lib.nixosSystem {
          system = lib.head config.systems;
          modules = [
            inputs.stylix.nixosModules.stylix
            polyModule
          ];
        };
      in
      {
        imports = [
          fakeSystem.config.stylix.targets.nixvim.exportedModule
        ];
      }
    );
  };

}
