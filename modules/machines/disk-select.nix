{ lib, self, slib, ... }:
{
  flake.modules.nixos.host-pc =
    { config, ... }:
    let
      inherit (lib) types mkOption;
      cfg = config.disk-select;

      evaluatorType = with types; functionTo int;
      knownEvaluatorType = with types; coercedTo str (name: cfg.evaluators.${name}) evaluatorType;
      requirementType = types.submodule {
        options.find = mkOption {
          type = types.listOf knownEvaluatorType;
          default = [
            "fastest"
            "largest"
          ];
        };
        options.priority = mkOption {
          type = types.int;
          default = 0;
        };
      };
    in
    {
      options.disk-select = {
        evaluators = mkOption {
          type = types.attrsOf evaluatorType;
        };
        required = mkOption {
          type = types.attrsOf requirementType;
          default = { };
        };
        result = mkOption {
          type = with types; attrsOf (nullOr nonEmptyStr);
          readOnly = true;
        };
      };

      config.disk-select.evaluators = rec {
        fastest =
          disk:
          if (lib.elem "nvme" (disk.drivers or [ ])) then
            -2
          else if (lib.hasInfix "SSD" (disk.model or "")) then
            -1
          else if (lib.elem "usb" (disk.drivers or [ ])) then
            1
          else
            0;
        smallest =
          disk:
          let
            calcSize = resource: resource.value_1 * resource.value_2;
            filterSizeResource = resource: (resource.type == "size") && ((resource.unit or "") == "sectors");
          in
          lib.pipe disk.resources [
            (builtins.filter filterSizeResource)
            lib.head
            calcSize
          ];
        largest = disk: -1 * (smallest disk);
      };

      config.disk-select.result =
        if cfg.required == { } then
          { }
        else
          (
            let
              inherit (config.hardware.facter) report;

              satisfy = slib.gale-shapley;

              disks = builtins.filter (
                disk:
                (builtins.elem "disk" disk.class_list)
                && (builtins.elem "block_device" disk.class_list)
                && (disk ? resources)
              ) report.hardware.disk;

              demandersPrioritized = lib.pipe cfg.required [
                lib.attrsToList
                (lib.sortOn (r: r.value.priority))
                (map (r: r.name))
              ];

              demanders = lib.mapAttrs (
                name: value:
                lib.pipe disks [
                  (lib.sort (
                    a: b:
                    lib.foldr (acc: x: if acc == 0 then x else acc) 0 (
                      map (evaluator: (evaluator a) - (evaluator b)) value.find
                    ) < 0
                  ))
                  (map (disk: lib.last disk.unix_device_names))
                ]
              ) cfg.required;

              suppliers = builtins.listToAttrs (
                lib.pipe disks [
                  (map (disk: disk.unix_device_names))
                  (map lib.last)
                  (map (name: {
                    inherit name;
                    value = demandersPrioritized;
                  }))
                ]
              );
            in
            (builtins.addErrorContext (toString demanders) (satisfy demanders suppliers))
          );
    };
}
