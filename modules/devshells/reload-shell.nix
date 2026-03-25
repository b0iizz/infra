{
  flake.modules.devshell.reload-shell =
    {
      lib,
      pkgs,
      flakeName,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      env = [
        {
          name = "FLAKE";
          eval = "\${FLAKE:=\${PRJ_ROOT:=$PWD}}";
        }
        {
          name = "PRJ_ROOT";
          eval = "\${FLAKE}";
        }

      ];
      packages = [ pkgs.nix ];
      commands = [
        {
          help = "Reloads this shell";
          name = "reload-shell";
          command = ''
            echo "Something went wrong. This script should be shadowed by a shell function!"
            exit 1
          '';
        }
      ];
      devshell.startup.reload-shell = lib.noDepEntry ''
        reload-shell() {
        	if nix build --no-link --show-trace "''${FLAKE}#devShells.${system}.${flakeName}" ; then
            set -- nix develop "''${FLAKE}#devShells.${system}.${flakeName}"
        	  exec $@
        	fi;
        }
      '';
    };
}
