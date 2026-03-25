{
  lib,
  config,
  inputs,
  self,
  ...
}@toplevel:
{
  flake.modules.nixos.host-vm =
    {
      config,
      configurationName,
      pkgs,
      modulesPath,
      ...
    }:
    let
      hostKeyName = config.installer.hostKeyName;
      hostKeyLocation = config.installer.hostKeyLocation;
      nixBuildArgs =
        extraArgs:
        "--extra-experimental-features 'nix-command flakes' build -L --no-link ${extraArgs} '${self}#nixosConfigurations.${configurationName}.config.system.build.vm'";
    in
    {
      imports = [
        "${toString modulesPath}/virtualisation/qemu-vm.nix"
      ];

      virtualisation.sharedDirectories.installer-vm-ssh-share = {
        source = "$VM_HOST_KEY_LOCATION";
        target = hostKeyLocation;
        securityModel = "mapped-xattr";
      };

      virtualisation.graphics = lib.mkDefault true;
      virtualisation.qemu.options =
        if (pkgs.stdenv.hostPlatform.system == "x86_64-linux") then
          [
            "-display gtk,gl=on"
            "-device virtio-vga-gl"
          ]
        else
          [ ];

      system.activationScripts.ssh-keys-vm.text = ''
        chown 755 ${hostKeyLocation}
        chmod 400 '${hostKeyLocation}/${hostKeyName}' '${hostKeyLocation}/${hostKeyName}.pub'
        chown -R root:root '${hostKeyLocation}'
      '';

      installer.name = "run-${configurationName}";

      installer.hostKeyLocation = "/etc/ssh/vm";

      installer.prepareStep = hostPkgs: ''
        ${
          lib.optionalString (hostPkgs.stdenv.hostPlatform.system != pkgs.stdenv.buildPlatform.system) ''
            ${lib.getExe hostPkgs.nix} --show-trace --option system "${pkgs.stdenv.buildPlatform.system}" --option keep-going true ${nixBuildArgs "\${NIX_CLI_OPTIONS}"} || true 
          ''
        }value] [--show-trace] [--
        VM_PATH=$(${lib.getExe hostPkgs.nix} ${nixBuildArgs "--print-out-paths \${NIX_CLI_OPTIONS}"})

        export VM_HOST_KEY_LOCATION=$(${hostPkgs.coreutils}/bin/mktemp -d)
        log "Host key directory is ''${VM_HOST_KEY_LOCATION}"

        cleanup() {
          ${hostPkgs.coreutils}/bin/rm -rf "''${VM_HOST_KEY_LOCATION}" 2>/dev/null || true
        }
        trap cleanup EXIT

        setup_host_keys ''${VM_HOST_KEY_LOCATION} 777 777 0

        CUSTOM_EXECUTOR=""
        if [[ ! -e "/etc/nixos" ]]; then
          log_warn "Running on non nixos system. Running with nixGL"
          CUSTOM_EXECUTOR="nix --extra-experimental-features nix-command --extra-experimental-features flakes run --impure github:nix-community/nixGL --"
        fi
      '';

      installer.installStep = ''
        ''${CUSTOM_EXECUTOR} ''${VM_PATH}/bin/run-${config.system.name}-vm $@
      '';

      installer.supportedSystems = lib.singleton config.virtualisation.host.pkgs.stdenv.hostPlatform.system;
    };

  builders.mkVirtualMachineConfig =
    {
      hostName,
      configurationBaseName ? hostName,
      module ? { },
      system,
      systems ? config.systems,
      defaultModules ? (
        with config.flake.modules.nixos;
        [
          base
          host-vm
        ]
      ),
      extraModules ? [ ],
    }:
    lib.foldl' (acc: c: acc // c) { } (
      map (
        hostSystem:
        config.builders.mkNixosConfig {
          inherit
            hostName
            module
            system
            defaultModules
            ;
          configurationName =
            configurationBaseName + (lib.optionalString (hostSystem != system) "-on-${hostSystem}");
          extraModules =
            extraModules
            ++ lib.singleton {
              virtualisation.host.pkgs = lib.mkForce (import inputs.nixpkgs { system = hostSystem; });
            };
        }
      ) systems
    );
}
