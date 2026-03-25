{
  lib,
  self,
  inputs,
  withSystem,
  ...
}:
{

  imports = [
    (inputs.agenix-rekey.flakeModule or {
      options.agenix-rekey = lib.mkOption { type = lib.types.raw; };
    }
    )
  ];

  config = lib.mkMerge [
    {
      flake-file.inputs.agenix.url = "github:ryantm/agenix";
      flake-file.inputs.agenix-rekey.url = "github:oddlama/agenix-rekey";
      flake-file.inputs.agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    }
    (lib.mkIf (inputs ? agenix-rekey) {
      #Make agenix-rekey available in all devshells
      flake.modules.devshell.base =
        { pkgs, ... }:
        {
          packages = [
            (withSystem (pkgs.stdenv.hostPlatform.system) ({ config, ... }: config.agenix-rekey.package))
          ];
        };

      #Configure agenix-rekey in all nixos configurations
      flake.modules.nixos.base =
        { config, pkgs, ... }:
        {
          imports = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
          ];

          age.rekey = {
            agePlugins = [
              inputs.nixpkgs.legacyPackages.x86_64-linux.age-plugin-fido2-hmac
              pkgs.age-plugin-fido2-hmac
            ];
            masterIdentities = [
              {
                identity = "${self}/master-id-fido2.pub";
                pubkey = "age1dje4dzshqf32v9sz48kqj5r9fcxd59cxpkmsh3rl8crul7wjrg7qh8jk72";
              }
            ];
            extraEncryptionPubkeys = [
            ];
            storageMode = "local";
            localStorageDir = "${self}/secrets/rekeyed/${config.networking.hostName}";
            generatedSecretsDir = "${self}/secrets/generated/${config.networking.hostName}";
          };
          age.ageBin = lib.getExe pkgs.age;
        };

      perSystem =
        { pkgs, ... }:
        {
          agenix-rekey.agePackage = pkgs.age;
        };

      #Creates a module that generates a secret hashed password file
      # useful for setting up user passwords
      builders.mkPasswordModule =
        {
          name,
          script ? "passphrase",
        }:
        { config, ... }:
        {
          age.secrets."${name}-raw" = {
            generator = {
              inherit script;
              tags = [
                "password"
                "plaintext-pw"
              ];
            };
            intermediary = true;
          };

          age.secrets.${name} = {
            generator = {
              tags = [
                "password"
                "hashed-pw"
              ];
              dependencies = [ config.age.secrets."${name}-raw" ];
              script =
                {
                  pkgs,
                  lib,
                  decrypt,
                  deps,
                  ...
                }:
                ''
                  ${decrypt} ${lib.escapeShellArg (lib.head deps).file} | \
                    ${lib.getExe pkgs.openssl} passwd -6 -stdin
                '';
            };
          };
        };

    })
  ];
}
