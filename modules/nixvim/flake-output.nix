{
  self,
  lib,
  config,
  ...
}:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim";

  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = lib.singleton self.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
      environment.variables.EDITOR = lib.mkOverride 900 "nvim";
      environment.pathsToLink = lib.singleton "/share/nvim";
    };

  flake.modules.nixvim.base = {
    viAlias = true;
    vimAlias = true;
    waylandSupport = true;
    opts.number = true;
  };

  perSystem =
    { inputs', pkgs, ... }:
    {
      packages.nixvim = inputs'.nixvim.legacyPackages.makeNixvimWithModule {
        inherit pkgs;
        module = config.flake.modules.nixvim.base;
      };
    };
}
