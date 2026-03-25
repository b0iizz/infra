{ lib, self-lib, ... }:
let
  sortOrdersOn = rec {
    fastest =
      disk:
      if (lib.elem "nvme" (disk.drivers or [ ])) then
        -2
      else
        (
          if (lib.hasInfix "SSD" (disk.model or "")) then
            -1
          else
            (if (lib.elem "usb" (disk.drivers or [ ])) then 1 else (0))
        );
    smallest =
      disk:
      let
        calcSize = res: res.value_1 * res.value_2;
        filterSize = res: (res.type == "size") && ((res.unit or "") == "sectors");
        resource = lib.elemAt 0 (builtins.filter filterSize disk.resources);
      in
      (calcSize resource);
    largest = disk: -1 * (smallest disk);
  };

  inherit (self-lib) galeShapleyUnequal;
in
{
  flake.modules.nixos.disk-select-facter =
    { config, ... }:
    {
      config.disk-select.result =
        lib.mkIf ((config.facter ? report) && (config.facter.report.hardware ? disk))
          (
            let
              inherit (config.facter) report;

              disks = builtins.filter (
                disk:
                (builtins.elem "disk" disk.class_list)
                && (builtins.elem "block_device" disk.class_list)
                && (disk ? resources)
              ) report.hardware.disk;

              demandersPrioritized = lib.sortOn (
                demander: -1 * (config.disk-select.required.${demander}.priority)
              ) (builtins.attrNames config.disk-select.required);

              demanders = builtins.mapAttrs (
                name: value:
                lib.pipe disks (lib.map (order: lib.sortOn (sortOrdersOn.${order})) (lib.reverseList value.find))
                ++ [
                  (disk: disk.unix_device_names)
                  lib.tail
                ]
              ) config.disk-select.required;

              suppliers = builtins.listToAttrs (
                lib.pipe disks [
                  (disk: disk.unix_device_names)
                  lib.tail
                  (name: {
                    inherit name;
                    value = demandersPrioritized;
                  })
                ]
              );
            in
            galeShapleyUnequal demanders suppliers
          );
    };
}
