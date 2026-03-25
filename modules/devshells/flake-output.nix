{
  self,
  lib,
  flake-parts-lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    (inputs.devshell.flakeModule or {
      options.perSystem = flake-parts-lib.mkPerSystemOption {
        options.devshells = lib.mkOption { type = lib.types.raw; };
      };
    }
    )
  ];

  flake-file.inputs.devshell.url = "github:numtide/devshell";

  flake.modules.devshell.base = { };
  flake.modules.devshell.unlocked =
    { pkgs, ... }:
    {
      age = {
        identityPaths = [
          "${self}/master-id-fido2.pub"
        ];
        extraPlugins = [
          pkgs.age-plugin-fido2-hmac
        ];
      };
    };

  perSystem.devshells = {
    default = {
      _module.args.flakeName = "default";
      imports = with config.flake.modules.devshell; [
        base
        reload-shell
      ];
    };
    unlocked = {
      _module.args.flakeName = "unlocked";
      imports = with config.flake.modules.devshell; [
        base
        reload-shell
        unlocked
      ];
    };

  };
}
