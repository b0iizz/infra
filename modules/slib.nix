{
  lib,
  inputs,
  config,
  ...
}:
{
  options.infuse.extra-sugars = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options.name = lib.mkOption { type = lib.types.str; };
        options.value = lib.mkOption { type = lib.types.raw; };
      }
    );
    default = [ ];
  };

  config = {
    flake-file.inputs.infuse = {
      url = "git+https://codeberg.org/amjoseph/infuse.nix?ref=trunk";
      flake = false;
    };

    _module.args.slib =
      let
        slib = import ../lib { inherit lib; };
        infuse = import inputs.infuse {
          inherit lib;
          sugars = infuse.v1.default-sugars ++ config.infuse.extra-sugars;
        };
      in
      slib // infuse.v1;
  };
}
