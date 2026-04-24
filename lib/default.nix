{ lib, ... }:
lib.fix (
  final:
  let
    gale-shapley = import ./gale-shapley.nix { lib = final; };
    toXml = import ./toXML.nix { lib = final; };
  in
  lib
  // {
    inherit gale-shapley toXml;
  }
)
