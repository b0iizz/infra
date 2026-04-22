{ lib, config, ... }@toplevel:
{
  flake.modules.nixos.base =
    { config, ... }:
    let
      inherit (toplevel.config.meta) owner;
    in
    {
      imports = [
        (toplevel.config.builders.mkPasswordModule { name = "root-password"; })
      ];

      options.settings.enableOwnerUser = lib.mkEnableOption "enable the repository's owner's user" // {
        default = true;
      };

      config = lib.mkMerge [
        {
          users.mutableUsers = lib.mkDefault false;
          users.users.root = {
            isNormalUser = false;
            isSystemUser = true;
            hashedPasswordFile = config.age.secrets.root-password.path;
          };
        }
        (lib.mkIf (config.settings.enableOwnerUser) {
          users.users.${owner.username} = {
            isNormalUser = true;
            home = lib.mkDefault "/home/${owner.username}";
            createHome = true;
            description = owner.description;
            extraGroups = [
              "wheel"
              "networkmanager"
              "audio"
              "dialout"
            ];
            hashedPasswordFile = config.age.secrets."${owner.username}-password".path;
          };
          home-manager.users.${owner.username} = { };
        })
        (lib.mkIf (config.settings.enableOwnerUser) (
          toplevel.config.builders.mkPasswordModule { name = "${owner.username}-password"; } {
            inherit config;
          }
        ))
      ];
    };
}
