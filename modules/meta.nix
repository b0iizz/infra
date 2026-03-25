{ lib, ... }:
{
  options.meta.owner = lib.mkOption {
    type = lib.types.submodule {
      options = {
        username = lib.mkOption {
          type = lib.types.singleLineStr;
        };
        email = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
        };
      };
    };
    readOnly = true;
    default = {
      username = "joni";
    };
  };
}
