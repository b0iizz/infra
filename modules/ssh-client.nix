{
  self,
  lib,
  config,
  ...
}@toplevel:
{
  flake.modules.nixos.base =
    { config, ... }:
    let
      inherit (toplevel.config.meta) owner;
    in
    {
      config = lib.mkMerge [
        {
          age.secrets."${owner.username}-ssh-ed25519" = {
            rekeyFile = "${self}/secrets/manual/${owner.username}-ssh-ed25519.age";
            generator.script = "ssh-ed25519";
            mode = "600";
            owner = owner.username;
            group = "wheel";
          };
        }
        (lib.mkIf (config.settings.enableOwnerUser) {
          home-manager.users.${owner.username} = {
            programs.ssh = {
              enable = true;
              enableDefaultConfig = false;
              matchBlocks."*" = {
                identityFile = lib.mkBefore [
                  config.age.secrets."${owner.username}-ssh-ed25519".path
                ];
                forwardAgent = false;
                addKeysToAgent = "no";
                compression = false;
                serverAliveInterval = 0;
                serverAliveCountMax = 3;
                hashKnownHosts = false;
                userKnownHostsFile = "~/.ssh/known_hosts";
                controlMaster = "no";
                controlPersist = "no";
              };
            };
          };
        })
      ];
    };
}
