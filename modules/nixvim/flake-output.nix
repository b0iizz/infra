{
  lib,
  config,
  inputs,
  ...
}:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim";

  flake.modules.nixvim.base = {
    viAlias = true;
    vimAlias = true;
    waylandSupport = true;
    opts.number = true;
  };

  perSystem =
    { inputs', pkgs, ... }:
    {
      packages.nixvim =
        if inputs' ? nixvim then
          (inputs'.nixvim.legacyPackages.makeNixvimWithModule {
            inherit pkgs;
            module = config.flake.modules.nixvim.base;
          })
        else
          pkgs.nvim;
    };
}
