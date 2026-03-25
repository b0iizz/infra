{ self, ... }:
{
  config.flake.modules.devshell.base =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      env = [
        {
          name = "EDITOR";
          value = lib.getExe self.packages.${system}.nixvim;
        }

      ];
      packages = [
        pkgs.coreutils
        pkgs.zig
        self.packages.${system}.nixvim
      ];

    };
}
