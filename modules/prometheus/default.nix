{ self, config, ... }:
{
  flake.nixosConfigurations = config.builders.mkNixosConfig {
    hostName = "prometheus";
    module = self.nixosModules.prometheusConfiguration;
  };
}
