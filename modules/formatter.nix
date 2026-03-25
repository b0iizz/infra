{
  lib,
  flake-parts-lib,
  inputs,
  ...
}:
{
  imports = [
    (inputs.treefmt-nix.flakeModule or {
      options.perSystem = flake-parts-lib.mkPerSystemOption {
        options.treefmt = lib.mkOption { type = lib.types.raw; };
      };
    }
    )
  ];

  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          prettier.enable = true;
          shfmt.enable = true;
          nixfmt = {
            enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt.compiler;
            package = pkgs.nixfmt;
          };
        };
        settings = {
          on-unmatched = "fatal";
          global.excludes = [
            "*.jpg"
            "*.png"
            "LICENSE"
            "*.pub"
            "*.age"
          ];
        };
      };
    };
}
