{ inputs, ... }:
{
  imports = [
    (inputs.flake-parts.flakeModules.modules or { })
    (inputs.flake-parts.flakeModules.flakeModules or { })
    inputs.flake-file.flakeModules.default
  ];

  systems = import inputs.systems;

  flake-file = {
    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      nixpkgs-lib.follows = "nixpkgs";

      flake-parts.url = "github:hercules-ci/flake-parts";
      flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      import-tree.url = "github:vic/import-tree";
      systems.url = "github:nix-systems/default-linux";

      flake-file.url = "github:vic/flake-file";
    };

    outputs = ''
      inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
    '';

    nixConfig = {
      trusted-substituters = [
        "https://cachix.cachix.org"
        "https://niri.cachix.org"
        "https://nixpkgs.cachix.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://numtide.cachix.org"
      ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };
  };

  flake.modules = { };
}
