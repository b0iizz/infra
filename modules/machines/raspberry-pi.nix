{
  lib,
  self,
  config,
  inputs,
  ...
}:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  flake.modules.nixos.host-rpi-3 = {
    imports = [
      config.flake.modules.nixos.host-rpi-common
    ]
    ++ (lib.optional (inputs ? nixos-hardware) inputs.nixos-hardware.nixosModules.raspberry-pi-3);

    hardware.deviceTree.enable = true;
  };

  flake.modules.nixos.host-rpi-4 = {
    imports = [
      config.flake.modules.nixos.host-rpi-common
    ]
    ++ (lib.optional (inputs ? nixos-hardware) inputs.nixos-hardware.nixosModules.raspberry-pi-4);

    hardware = {
      raspberry-pi."4" = {
        apply-overlays-dtmerge.enable = true;
        fkms-3d.enable = true;
      };
      deviceTree = {
        enable = true;
      };
    };
  };

  flake.modules.nixos.host-rpi-common =
    {
      pkgs,
      config,
      modulesPath,
      configurationName,
      ...
    }:
    {
      imports = [
        "${toString modulesPath}/installer/sd-card/sd-image-aarch64.nix"
      ];

      hardware.enableRedistributableFirmware = lib.mkForce false;
      hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

      users.groups.gpio = { };

      services.udev.extraRules = ''
        KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
          SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys/class/gpio && ${pkgs.coreutils}/bin/chmod -R g=u /sys/class/gpio'"
          SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys%p && ${pkgs.coreutils}/bin/chmod -R g=u /sys%p'"
      '';

      boot = {
        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
          timeout = 2;
        };

        swraid.enable = lib.mkForce false;
      };

      environment.systemPackages = with pkgs; [
        libraspberrypi
        raspberrypi-eeprom
      ];

      nixpkgs.hostPlatform = lib.mkForce lib.systems.examples.aarch64-multiplatform;

      installer =
        let
          nixBuildArgs =
            extraArgs:
            "--extra-experimental-features 'nix-command flakes' build -L --no-link ${extraArgs} '${self}#nixosConfigurations.${configurationName}.config.system.build.sdImage'";
        in
        {
          arguments.yes = { };
          arguments.output = {
            isSimple = false;
            default = "";
          };

          validationStep = lib.mkAfter [
            (hostPkgs: ''
              if [[ -n "''${${config.installer.arguments.output.variable}}" ]]; then
                device="''${${config.installer.arguments.output.variable}}"
              else
                devicename=$(
                  ${hostPkgs.util-linux}/bin/lsblk -o "NAME,TYPE,RM" -P \
                    | ${hostPkgs.gnugrep}/bin/grep 'TYPE="disk" RM="1"' \
                    | ${hostPkgs.gawk}/bin/awk -F'"' '{print $2}'
                )

                device=""
                [[ -n "''${devicename}" ]] && device="/dev/''${devicename}"

                if [[ ! "''${${config.installer.arguments.yes.variable}}" -eq 1 ]]; then
                  echo
                  read -p "Specify the device name to write the image to (''${device:-no device found}): " REPLY
                  [[ -n "''${REPLY}" ]] && device="''${REPLY}"
                fi
              fi

              [[ -n "''${device}" ]] || { die "No target specified"; }

              if [[ -b "''${device}" ]]; then
                TARGET_TYPE="block"
              elif [[ -f "''${device}" ]] || [[ ! -e "''${device}" ]]; then
                TARGET_TYPE="file"
              else
                die "Invalid target: ''${device}"
              fi

              log "Target: ''${device}"
            '')
          ];

          prepareStep = hostPkgs: ''
            ${lib.optionalString (hostPkgs.stdenv.hostPlatform.system != pkgs.stdenv.buildPlatform.system) ''
              ${lib.getExe hostPkgs.nix} --show-trace --option system "${pkgs.stdenv.buildPlatform.system}" --option keep-going true ${nixBuildArgs "\${NIX_CLI_OPTIONS}"} || true 
            ''}
            INPUT_IMAGE_PATH=$(${lib.getExe hostPkgs.nix} ${nixBuildArgs "--print-out-paths \${NIX_CLI_OPTIONS}"})
            INPUT_IMAGE=$(find "''${INPUT_IMAGE_PATH}" -name "*.img.*" -xtype f -print -quit)


            WORK_IMG=$(${hostPkgs.coreutils}/bin/mktemp img_uncompressed.XXXX)
            MODIFIED_IMG=$(${hostPkgs.coreutils}/bin/mktemp img_final.XXXX)

            log "Preparing image"
            case "''${INPUT_IMAGE}" in
              *.zst)
                log "Decompressing zstd image"
                ${lib.getExe hostPkgs.zstd} -d --stdout "''${INPUT_IMAGE}" > "''${WORK_IMG}"
                ;;
              *.img)
                log "Using uncompressed image"
                ${hostPkgs.coreutils}/bin/cp "''${INPUT_IMAGE}" "''${WORK_IMG}"
                ;;
              *)
                log_error "Unsupported image format: ''${INPUT_IMAGE}"
                exit 1
                ;;
            esac

            MOUNT_DIR=$(${hostPkgs.coreutils}/bin/mktemp -d)
            log "Mount directory: ''${MOUNT_DIR}"

            cleanup() {
              sudo ${hostPkgs.util-linux}/bin/umount "''${MOUNT_DIR}" 2>/dev/null || true
              ${hostPkgs.coreutils}/bin/rmdir "''${MOUNT_DIR}" 2>/dev/null || true
              ${hostPkgs.coreutils}/bin/rm -f ''${WORK_IMG} ''${MODIFIED_IMG} || true
              if [[ -n "''${LOOP_DEVICE:-}" ]]; then
                sudo ${hostPkgs.util-linux}/bin/losetup -d "''${LOOP_DEVICE}" 2>/dev/null || true
              fi
            }
            trap cleanup EXIT

            LOOP_DEVICE=$(sudo ${hostPkgs.util-linux}/bin/losetup -f)
            sudo ${hostPkgs.util-linux}/bin/losetup -P "''${LOOP_DEVICE}" "''${WORK_IMG}"
            log "Loop device: ''${LOOP_DEVICE}"

            ${hostPkgs.coreutils}/bin/sync

            ROOT_PARTITION=$(
              sudo ${hostPkgs.util-linux}/bin/lsblk -rno NAME,LABEL "''${LOOP_DEVICE}" \
                | ${hostPkgs.gnugrep}/bin/grep -i "NIXOS_SD" \
                | ${hostPkgs.gawk}/bin/awk '{print $1}'
            )

            [[ -n "''${ROOT_PARTITION}" ]] || { die "Could not find root partition"; } 

            log "Mounting root partition /dev/''${ROOT_PARTITION}"
            sudo ${hostPkgs.util-linux}/bin/mount "/dev/''${ROOT_PARTITION}" "''${MOUNT_DIR}"

            log "Injecting host keys"
            sudo ${hostPkgs.coreutils}/bin/mkdir -p "''${MOUNT_DIR}${config.installer.hostKeyLocation}"
            setup_host_keys "''${MOUNT_DIR}${config.installer.hostKeyLocation}" 775 600 1

            log "Unmounting root partition"
            sudo ${hostPkgs.util-linux}/bin/umount "''${MOUNT_DIR}"

            log "Creating modified image"
            ${hostPkgs.coreutils}/bin/dd if="''${WORK_IMG}" of="''${MODIFIED_IMG}" bs=4M status=progress
            ${hostPkgs.coreutils}/bin/sync
          '';

          installStep = hostPkgs: ''
            if [[ "''${${config.installer.arguments.yes.variable}}" -eq 1 ]]; then
              CONFIRM=yes
            else
              echo
              read -p "Install on ''${device}? [y/N] " -n 1 -r
              echo
              [[ "''${REPLY}" =~ ^[Yy]$ ]] && CONFIRM=yes || CONFIRM=no
            fi

            [[ "''${CONFIRM}" = yes ]] || { log_warn "Aborted"; exit 0; }

            if [[ "''${TARGET_TYPE}" = block ]]; then
              log "Unmounting existing partitions"
              for part in $(
                ${lib.getExe hostPkgs.gnused} -n "/$(${hostPkgs.coreutils}/bin/basename "''${device}")[a-z]*[0-9]/ s,.* ,/dev/,p" \
                /proc/partitions
              ); do
                log "Unmounting ''${part}"
                sudo ${hostPkgs.util-linux}/bin/umount "''${part}" 2>/dev/null || true
              done

              sudo ${hostPkgs.coreutils}/bin/dd bs=4M if="''${MODIFIED_IMG}" of="''${device}" status=progress
            else
              ${hostPkgs.coreutils}/bin/dd bs=4M if="''${MODIFIED_IMG}" of="''${device}" status=progress
            fi
            ${hostPkgs.coreutils}/bin/sync

            log "Write complete"
          '';
        };
    };
}
