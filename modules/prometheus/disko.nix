{ ... }:
{
  flake.nixosModules.prometheusConfiguration =
    { config, ... }:
    {

      disk-select.required.main = {
        find = [
          "fastest"
          "smallest"
        ];
        priority = 0;
      };

      disko.devices = {
        disk = {
          main = {
            device = config.disk-select.result.main;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "500M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                root = {
                  end = "-1G";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
                plainSwap = {
                  size = "100%";
                  content = {
                    type = "swap";
                    discardPolicy = "both";
                    resumeDevice = true; # resume from hiberation from this device
                  };
                };
              };
            };
          };
        };
      };
    };
}
