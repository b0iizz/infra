{ lib, config, ... }@toplevel:
let
  inherit (lib)
    hasPrefix
    remove
    elem
    head
    pipe
    range
    optional
    optionalString
    optionalAttrs
    concatStringsSep
    fixedWidthString
    stringLength
    attrValues
    mapAttrs'
    filterAttrs
    mkOption
    mkOptionDefault
    mkOrder
    types
    ;

in
{
  perSystem =
    { pkgs, ... }:
    {
      apps = filterAttrs (_: v: v.program != null) (
        mapAttrs' (
          name: nixos:
          let
            package = nixos.config.installer.makeInstaller pkgs;
          in
          {
            name = nixos.config.installer.name;
            value = {
              meta.description = "Builds and installs configuration '${name}'";
              program = package;
            };
          }
        ) (config.flake.nixosConfigurations or { })
      );
    };

  flake.modules.nixos.base =
    {
      config,
      configurationName,
      ...
    }:
    let
      cfg = config.installer;
      mergedArgsNames = map (arg: arg.name) (attrValues cfg.arguments);
      shortArgumentFor =
        arg:
        let
          candidates = pipe (range 1 (lib.min (builtins.stringLength arg) 3)) [
            (map (end: builtins.substring 0 end arg))
            (builtins.filter (p: !builtins.any (a: hasPrefix p a) (remove arg mergedArgsNames)))
          ];
        in
        if arg == null || candidates == [ ] then null else (head candidates);

      initArgument = arg: ''
        ${arg.variable}=${arg.default or ''""''}
        ${optionalString (arg.default == null) ''
          __${arg.variable}_set=0
        ''}
      '';

      invertValue =
        val:
        if val == null then
          "1"
        else if val == "0" then
          "1"
        else if val == "1" then
          "0"
        else if val == "" then
          "1"
        else
          "";

      parseArgument = arg: ''
        --${arg.name}${optionalString (arg.shorthand != null) "|-${arg.shorthand}"})
          ${optionalString (arg.isSimple) ''
            ${arg.variable}=${invertValue arg.default}
          ''}
          ${optionalString (!arg.isSimple) ''
            [[ "$#" -ge 2 ]] || die "Too few arguments for $1"
            ${arg.variable}="$2"
            shift
          ''}
          ${optionalString (arg.default == null) ''
            __${arg.variable}_set=1
          ''}
          ;;
      '';

      validateArgument =
        arg:
        optionalString (arg.default == null) ''
          [[ ''${__${arg.variable}_set} -eq 1 ]] || die "Please specify ${arg.name}${
            optionalString (arg.shorthand != null) " or ${arg.shorthand}"
          }"
        '';

      handleArguments = args: ''
        ${concatStringsSep "\n" (map initArgument args)}

        while [[ "$#" -gt 0 ]]; do
          case "$1" in
            ${concatStringsSep "\n" (map parseArgument args)}
            --)
              break
              ;;
            *)
              log_error "Unrecognised argument '$1'. Use '--help' for help and end argument parsing with '--'"
          esac
          shift
        done

        ${concatStringsSep "\n" (map validateArgument args)}
      '';

      toHelpArgument =
        width: arg:
        (if width > 0 then (fixedWidthString width " ") else lib.id)
          "--${arg.name}${optionalString (arg.shorthand != null) ", -${arg.shorthand}"}";
      toHelpType =
        width: arg:
        (if width > 0 then (fixedWidthString width " ") else lib.id) (
          optionalString (!arg.isSimple) "value"
        );
      toHelpDefault =
        width: arg:
        (if width > 0 then (fixedWidthString width " ") else lib.id) (
          if (arg.default == null) then "(required)" else "[${arg.default}]"
        );
      toHelpDescription =
        width: arg:
        (if width > 0 then (fixedWidthString width " ") else lib.id) (
          optionalString (arg.description != null) arg.description
        );

      helpHeadings = {
        argument = "COMMAND";
        type = "";
        default = "DEFAULT";
        description = "DESCRIPTION";
      };

      helpWidths = {
        argument = (
          builtins.foldl' lib.max (stringLength helpHeadings.argument) (
            pipe cfg.arguments [
              attrValues
              (map (toHelpArgument 0))
              (map stringLength)
            ]
          )
        );
        type = (
          builtins.foldl' lib.max (stringLength helpHeadings.type) (
            pipe cfg.arguments [
              attrValues
              (map (toHelpType 0))
              (map stringLength)
            ]
          )
        );
        default = (
          builtins.foldl' lib.max (stringLength helpHeadings.default) (
            pipe cfg.arguments [
              attrValues
              (map (toHelpDefault 0))
              (map stringLength)
            ]
          )
        );
        description = (
          builtins.foldl' lib.max (stringLength helpHeadings.description) (
            pipe cfg.arguments [
              attrValues
              (map (toHelpDescription 0))
              (map stringLength)
            ]
          )
        );
      };

      helpForArgument =
        arg:
        concatStringsSep "\t" [
          (toHelpArgument helpWidths.argument arg)
          (toHelpType helpWidths.type arg)
          (toHelpDefault helpWidths.default arg)
          (toHelpDescription helpWidths.description arg)
        ];

      printHelpForArgument = arg: ''
        echo '${helpForArgument arg}'
      '';

      printHeading = ''
        echo '${
          concatStringsSep "\t" (
            map (name: toHelpDescription helpWidths.${name} { description = helpHeadings.${name}; }) [
              "argument"
              "type"
              "default"
              "description"
            ]
          )
        }'
      '';
      printHelp = concatStringsSep "\n" (map printHelpForArgument (attrValues cfg.arguments));

    in
    {
      options.installer = {

        name = mkOption {
          type = types.str;
          default = "install-${configurationName}";
        };

        makeInstaller = mkOption {
          type = types.functionTo (types.nullOr types.package);
          internal = true;
          readOnly = true;
        };

        supportedSystems = mkOption {
          type = types.listOf types.str;
          default = toplevel.config.systems;
        };

        arguments = mkOption {
          type = types.attrsOf (
            types.submodule (
              { config, name, ... }:
              {
                options = {
                  name = mkOption {
                    type = types.str;
                    default = name;
                  };
                  shorthand = mkOption {
                    type = types.nullOr types.str;
                    default = shortArgumentFor config.name;
                  };
                  variable = mkOption {
                    type = types.str;
                    default = config.name;
                  };
                  default = mkOption {
                    type = types.nullOr (types.coercedTo types.unspecified toString types.str);
                    default = if (config.isSimple) then false else null;
                  };
                  isSimple = mkOption {
                    type = types.bool;
                    default = true;
                  };
                  description = mkOption {
                    type = types.singleLineStr;
                    default = "";
                  };
                };
              }
            )
          );
          default = { };
        };

        validationStep = mkOption {
          type = types.listOf (types.coercedTo types.lines (val: _: val) (types.functionTo types.lines));
          default = [ ];
        };

        prepareStep = mkOption {
          type = types.coercedTo types.lines (val: _: val) (types.functionTo types.lines);
          default = "";
        };

        installStep = mkOption {
          type = types.coercedTo types.str (val: _: val) (types.functionTo types.str);
          default = "echo \"TODO\" && exit 1";
        };

        hostKeyLocation = mkOption {
          type = types.str;
          default = "/etc/ssh";
        };

        hostKeyName = mkOption {
          type = types.str;
          default = "ssh_host_id25519_key";
        };

        hostKeyFileEnvVar = mkOption {
          type = types.str;
          default = "SECRET_${config.networking.hostName}_HOST_KEY_FILE";
        };
      };

      config.installer = {
        arguments = {
          dry-run = {
            variable = "DRY_RUN";
            description = "Perform a dry run of this installation";
          };
          help = {
            variable = "PRINT_HELP_MESSAGE";
            description = "Print this help message";
          };
        }
        // optionalAttrs (config ? age.rekey.hostPubkey) {
          host-key-file = {
            isSimple = false;
            name = "key";
            variable = "HOST_KEY_FILE";
            description = "The file that contains the machines host key.";
            default = "\${${cfg.hostKeyFileEnvVar}:-\"\"}";
          };
        };
        validationStep = [
          (mkOrder 100 (_: ''
            if [[ ''${${cfg.arguments.help.variable}} -eq 1 ]]; then
              ${printHeading}
              ${printHelp}
              exit 0
            fi
          ''))
        ]
        ++ optional (config ? age.rekey.hostPubkey) (hostPkgs: ''
          if [[ ! -f "''${${cfg.arguments.host-key-file.variable}}" ]]; then
            die "Could not find specified host key file: \"''${${cfg.arguments.host-key-file.variable}}\"."
          fi

          EXPECTED_HOST_PUBKEY="${config.age.rekey.hostPubkey}"
          ACTUAL_HOST_PUBKEY="$(${hostPkgs.openssh}/bin/ssh-keygen -y -f ''${${cfg.arguments.host-key-file.variable}})"
          if [[ "''${ACTUAL_HOST_PUBKEY}" != "''${EXPECTED_HOST_PUBKEY}" ]]; then
            log_error "expected: ''${EXPECTED_HOST_PUBKEY}"
            log_error "received: ''${ACTUAL_HOST_PUBKEY}"
            die "Host public keys do not match."
          fi


          setup_host_keys () {
            log "Setting up host keys..."
            if [[ $# -ne 4 ]]; then
              log_warn "Usage: setup_host_keys [location] [dirPerms] [filePerms] [setrootowner]"
              die "Incorrect invocation of setup_host_keys with " "$@"
            fi
            sudo ${hostPkgs.coreutils}/bin/chmod $2 "$1"
            sudo ${hostPkgs.coreutils}/bin/cp ''${${cfg.arguments.host-key-file.variable}} "$1/${cfg.hostKeyName}"
            echo "${config.age.rekey.hostPubkey}" | sudo ${hostPkgs.coreutils}/bin/tee "$1/${cfg.hostKeyName}.pub"
            sudo ${hostPkgs.coreutils}/bin/chmod $3 "$1/${cfg.hostKeyName}" "$1/${cfg.hostKeyName}.pub"
            if [[ "$4" -eq "1" ]]; then
              sudo ${hostPkgs.coreutils}/bin/chown -R root:root "$1"
            fi
          }
        '')

        ;
        makeInstaller =
          hostPkgs:
          let
            inherit (hostPkgs.stdenv.hostPlatform) system;
          in
          if (!elem system cfg.supportedSystems) then
            null
          else
            (hostPkgs.writeTextFile {
              name = "${cfg.name}-${system}";
              executable = true;
              destination = "/bin/install";
              meta.mainProgram = "install";
              text = ''
                #! ${hostPkgs.runtimeShell}
                set -euo pipefail

                log()       { echo "[36minfo:[0m $*" >&2; }
                log_warn()  { echo "[1;33mwarning:[0m $*" >&2; }
                log_error() { echo "[1;31merror:[0m $*" >&2; }
                die()       { log_error $*; exit 1; }

                NIX_CLI_OPTIONS=''${NIX_CLI_OPTIONS:-""}

                ${handleArguments (attrValues cfg.arguments)}

                ${concatStringsSep "\n" (map (step: step hostPkgs) cfg.validationStep)}

                log "Starting preparation..."
                ${cfg.prepareStep hostPkgs}

                if [[ ''${${cfg.arguments.dry-run.variable}} -eq 1 ]]; then
                  log "Quitting due to dry run!"
                else
                  log "Starting installation..."
                  ${cfg.installStep hostPkgs}
                fi
              '';
            });
      };

      config.services.openssh.extraConfig = mkOrder 1 ''
        HostKey ${cfg.hostKeyLocation}/${cfg.hostKeyName}
      '';

      config.age.identityPaths = mkOptionDefault [
        "${cfg.hostKeyLocation}/${cfg.hostKeyName}"
      ];
    };
}
