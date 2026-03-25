{ lib, ... }:
let
  requirementType = lib.types.submodule {
    options.find = lib.mkOption {
      type = lib.types.listOf lib.types.enum [
        "fastest"
        "largest"
        "smallest"
      ];
      default = [
        "fastest"
        "largest"
      ];
    };
    options.priority = lib.mkOption {
      type = lib.int;
      default = 0;
    };
  };
in
{
  flake.modules.nixos.disk-select-base = {
    options.disk-select.required = lib.mkOption {
      type = lib.types.attrsOf requirementType;
    };
    options.disk-select.result = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.nonEmptyStr);
      readOnly = true;
    };
  };
}
