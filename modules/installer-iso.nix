{ config, inputs, ...}: {
  flake.nixosConfigurations = config.builders.mkNixosConfig {
    hostName = "installer-iso";
    module = {pkgs, modulesPath,...}: { 
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal-combined.nix"
        "${modulesPath}/installer/cd-dvd/channel.nix"
      ];

      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      services.openssh = {
      	enable = true;
        settings = {
          PasswordAuthentication = false;
	  PermitRootLogin = "no";
        };
      };

      users.users."nixos".openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYJZQipCKx0rDKEYI6r+0MpUZKSVHZRafrOAF6dVP8J prometheus:joni-ssh-ed25519"
      ];
    };
  };
}
