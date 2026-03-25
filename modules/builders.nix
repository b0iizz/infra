{
  lib,
  inputs,
  config,
  ...
}@toplevel:
{
  options.builders = lib.mkOption {
    type = lib.types.attrsOf (lib.types.functionTo lib.types.raw);
  };

  config.builders = {
    mkNixosConfig =
      {
        hostName,
        configurationName ? hostName,
        module ? { },
        system ? null,
        defaultModules ? [ (config.flake.modules.nixos.base or { }) ],
        extraModules ? [ ],
      }:
      {
        ${configurationName} = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit configurationName; };
          modules = [
            module
            {
              networking.hostName = hostName;
            }
          ]
          ++ defaultModules
          ++ extraModules
          ++ lib.optional (system != null) {
            nixpkgs.hostPlatform = lib.mkDefault { inherit system; };
          };
        };
      };
  };
}
