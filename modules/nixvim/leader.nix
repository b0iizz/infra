{ lib, ... }:
{
  flake.modules.nixvim.base.globals =
    lib.pipe
      [ "mapleader" "maplocalleader" ]
      [ (lib.map (lib.flip lib.nameValuePair ",")) lib.listToAttrs ];
}
