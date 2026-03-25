{ self, ... }:
{
  # Copied and modified from agenix https://github.com/ryantm/agenix
  # and from agenix-rekey https://github.com/oddlama/agenix-rekey
  /*
    MIT License

    Copyright (c) 2023 oddlama

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  */

  config.flake.modules.devshell.base =
    {
      lib,
      pkgs,
      config,
      flakeName,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkOption
        mkEnableOption
        mkPackageOption
        types
        literalExpression
        optionalString
        concatStringsSep
        concatMapStrings
        escapeShellArg
        removeSuffix
        filter
        hasPrefix
        removePrefix
        isAttrs
        attrValues
        warn
        ;
      cfg = config.age;

      userFlakeDir = toString self.outPath;
      relativeToFlake =
        filePath:
        let
          fileStr = builtins.unsafeDiscardStringContext (toString filePath);
        in
        if hasPrefix userFlakeDir fileStr then
          "." + removePrefix userFlakeDir fileStr
        else
          warn "Ignoring ${fileStr} which isn't a direct subpath of the flake directory ${userFlakeDir}, meaning this script cannot determine it's true origin!" null;

      # Relative path to all rekeyable secrets. Filters and warns on paths that are not part of the root flake.
      validRelativeSecretPaths = builtins.sort (a: b: a < b) (
        filter (x: x != null) (
          lib.pipe (attrValues cfg.secrets) [
            (map (a: a.file))
            (map relativeToFlake)
          ]
        )
      );

      envPath = ''PATH="$PATH"${concatMapStrings (x: ":${escapeShellArg x}/bin") cfg.extraPlugins}'';
      decryptionMasterIdentityArgs = concatStringsSep " " (map (x: "-i ${x.identity}") cfg.identityPaths);

      ageBin = lib.getExe cfg.package;
      ageWrapperScript = pkgs.writeShellApplication {
        name = "ageWrapper";
        runtimeInputs = with pkgs; [ gnugrep ];
        text = ''
          # Redirect messages to stderr.
          warn() { echo "warning:" "$@" >&2; }
          error() { echo "error:" "$@" >&2; }

          # Collect identities in a dictionary with mapping:
          # pubkey -> identity file
          declare -A masterIdentityMap
          # Master identities that have a pubkey can be added without further treatment.
          ${concatStringsSep "\n" (
            map (x: "masterIdentityMap[${escapeShellArg (removeSuffix "\n" x.pubkey)}]=${x.identity}") (
              filter (x: x.pubkey != null) cfg.identityPaths
            )
          )}

          # For master identies with no explicit pubkey, try extracting a pubkey from the file first.
          # Collect final identity arguments for encryption in an array.
          masterIdentityArgs=()
          # shellcheck disable=SC2041,SC2043,SC2086
          for file in ${
            concatStringsSep " " (map (x: x.identity) (filter (x: x.pubkey == null) cfg.identityPaths))
          }; do
            # Keep track if a file was processed.
            file_processed=false
            age_plugin=""
            prefix=""
            pubkeys=()

            # Only consider files that contain exactly one identity, since files with multiple identities are allowed,
            # but are ambiguous with respect to the pairings between identities and pubkeys.
            if [[ $(grep -c "^AGE-" "$file") == 1 ]]; then
              if grep -q "^AGE-PLUGIN-YUBIKEY-" "$file"; then
                age_plugin="age-plugin-yubikey"
                prefix="Recipient: age1yubikey1"
                # If the file specifies "Recipient: age1yubikey1<pubkey>", extract recipient
                mapfile -t pubkeys < <(grep 'Recipient: age1yubikey1' "$file" | grep -Eoh 'age1yubikey1[0-9a-z]+')
              elif grep -q "^AGE-PLUGIN-FIDO2-HMAC-" "$file"; then
                age_plugin="age-plugin-fido2-hmac"
                prefix="public key: age1"
                # If the file specifies "public key: age1<pubkey>", extract public key
                mapfile -t pubkeys < <(grep 'public key: age1' "$file" | grep -Eoh 'age1[0-9a-z]+')
              fi

              if [[ -n "$age_plugin" ]]; then
                if [[ ''${#pubkeys[@]} -eq 0 ]]; then
                  error "Failed to find public key for master identity: $file"
                  error "If this is a keygrab, a comment should have been added by $age_plugin that seems to be missing here"
                  error "Please re-export the identity from $age_plugin or manually add the \"# $prefix<your_pubkey>\""
                  error "string in front of the key."
                  error "Alternatively, you can also specify the correct public key in \`config.age.rekey.masterIdentities\`."
                  exit 1
                # If one key, specify recipient via -r
                elif [[ ''${#pubkeys[@]} -eq 1 ]]; then
                  masterIdentityMap["''${pubkeys[0]}"]="$file"
                  masterIdentityArgs+=("-r" "''${pubkeys[0]}")
                  file_processed=true
                else
                  error "Found more than one public key in master identity: $file"
                  error "agenix-rekey only supports a one-to-one correspondence between identities and their pubkeys."
                  error "If this is not intended, please avoid the \"# $prefix: \" comment in front of the incorrect key."
                  error "Alternatively, specify the correct public key in \`config.age.rekey.masterIdentities\`."
                  error "List of public keys found in the file:"
                  for pubkey in "''${pubkeys[@]}"; do
                    error "  $pubkey"
                  done
                  exit 1
                fi
              fi
            fi

            # If the identity was not processed at this point, pass it to (r)age as a regular identity file,
            # so that the program can decide what to do with it.
            if [[ "$file_processed" == false ]]; then
              masterIdentityArgs+=("-i" "$file")
            fi
          done

          primaryIdentityArgs=()
          if [[ -n "''${AGENIX_REKEY_PRIMARY_IDENTITY:-}" ]]; then
            pubkey_found=false
            for pubkey in "''${!masterIdentityMap[@]}"; do
              if [[ "$pubkey" == "$AGENIX_REKEY_PRIMARY_IDENTITY" ]]; then
                primaryIdentityArgs=("-i" "''${masterIdentityMap["$pubkey"]}")
                pubkey_found=true
                break
              fi
            done
            if [[ "$pubkey_found" == false ]]; then
              warn "Environment variable AGENIX_REKEY_PRIMARY_IDENTITY is set, but matches none of the pubkeys found by agenix-rekey."
              warn "Please verify that your pubkeys and identities are set up correctly."
              warn "Value of AGENIX_REKEY_PRIMARY_IDENTITY: \"$AGENIX_REKEY_PRIMARY_IDENTITY\""
              warn "Pubkeys found:"
              for pubkey in "''${!masterIdentityMap[@]}"; do
                warn "  $pubkey for file \"''${masterIdentityMap["$pubkey"]}\""
              done
            fi
          fi

          # Use first argument to determine encryption mode.
          # Pass all other arguments to (r)age.
          if [[ "$1" == "encrypt" ]]; then
            ${envPath} ${ageBin} -e "''${masterIdentityArgs[@]}" "''${@:2}"
          else
            # Prepend primary key argument before all others to it gets the first attempt at decrypting.
            if [[ -n "''${AGENIX_REKEY_PRIMARY_IDENTITY:-}" ]] && [[ "''${AGENIX_REKEY_PRIMARY_IDENTITY_ONLY:-}" == true ]]; then
              ${envPath} ${ageBin} -d "''${primaryIdentityArgs[@]}" "''${@:2}"
            else
              # splitting args is intentional here, files with spaces must be quoted by the user
              extraArgs=(${decryptionMasterIdentityArgs})
              ${envPath} ${ageBin} -d "''${primaryIdentityArgs[@]}" "''${extraArgs[@]}" "''${@:2}"
            fi
          fi
        '';
      };

      rekeyScript = ''
        set -uo pipefail

        function die() { echo "error: $*" >&2; exit 1; }
        if [[ ! -e flake.nix ]] ; then
          die "Please execute this script in your flake's root directory."
        fi

        ${concatStringsSep "" (
          map (path: ''
            CLEARTEXT_FILE=$(mktemp)
            ENCRYPTED_FILE=$(mktemp)

            function cleanup() {
              [[ -e "$CLEARTEXT_FILE" ]] && rm "$CLEARTEXT_FILE"
              [[ -e "$ENCRYPTED_FILE" ]] && rm "$ENCRYPTED_FILE"
            }; trap "cleanup" EXIT

            agenix-devshell decrypt -o "$CLEARTEXT_FILE" "${path}" \
                || die "Failed to decrypt file. Aborting."
            agenix-devshell encrypt -o "$ENCRYPTED_FILE" "$CLEARTEXT_FILE" \
                || die "Failed to re-encrypt file. Aborting."

            cp --no-preserve=all "$ENCRYPTED_FILE" "${path}" # cp instead of mv preserves original attributes and permissions
            echo "Rekeyed file ${path}"
            rm "$CLEARTEXT_FILE"
            rm "$ENCRYPTED_FILE"
          '') validRelativeSecretPaths
        )}
        exit 0
      '';

      editScript = ''
        set -uo pipefail

        function die() { echo "error: $*" >&2; exit 1; }
        if [[ ! -e flake.nix ]] ; then
          die "Please execute this script in your flake's root directory."
        fi

        if [[ ! $# -gt 0 ]] ; then
          die "Please specify the file you want to edit."
        fi

        FILE="$1"

        [[ "$FILE" != *".age" ]] && echo "warning: secrets should use the .age suffix by convention"

        # Extract suffix before .age, if there is any.
        SUFFIX=$(basename "$FILE")
        SUFFIX=''${SUFFIX%.age}
        if [[ "''${SUFFIX}" == *.* ]]; then
          # Extract the second suffix if there is one
          SUFFIX=''${SUFFIX##*.}
        else
          # Use txt otherwise
          SUFFIX="txt"
        fi

        CLEARTEXT_FILE=$(mktemp --suffix=".$SUFFIX")
        ENCRYPTED_FILE=$(mktemp --suffix=".$SUFFIX")

        function cleanup() {
          [[ -e "$CLEARTEXT_FILE" ]] && rm "$CLEARTEXT_FILE"
          [[ -e "$ENCRYPTED_FILE" ]] && rm "$ENCRYPTED_FILE"
        }; trap "cleanup" EXIT

        if [[ -e "$FILE" ]]; then

          agenix-devshell decrypt -o "$CLEARTEXT_FILE" "$FILE" \
            || die "Failed to decrypt file. Aborting."
        else
          mkdir -p "$(dirname "$FILE")" \
            || die "Could not create parent directory"
        fi

        # Editor options to prevent leaking information
        EDITOR_OPTS=()
        case "$EDITOR" in
          *nvim*)
            EDITOR_OPTS=("--cmd" 'au BufRead * setlocal nobackup nomodeline noshelltemp noswapfile noundofile nowritebackup shadafile=NONE') ;;
          *vim*)
            EDITOR_OPTS=("--cmd" 'au BufRead * setlocal nobackup nomodeline noshelltemp noswapfile noundofile nowritebackup viminfo=""') ;;
          *) ;;
        esac
        $EDITOR "''${EDITOR_OPTS[@]}" "$CLEARTEXT_FILE" \
          || die "Editor returned unsuccessful exit status. Aborting, original is left unchanged."

        agenix-devshell encrypt -o "$ENCRYPTED_FILE" "$CLEARTEXT_FILE" \
          || die "Failed to (re)encrypt edited file, original is left unchanged."
        cp --no-preserve=all "$ENCRYPTED_FILE" "$FILE" # cp instead of mv preserves original attributes and permissions

        exit 0

      '';

      newGeneration = ''
        mkdir -p ${lib.dirOf cfg.secretsDir}
        _agenix_generation="$(basename "$(readlink "${cfg.secretsDir}")" || echo 0)"
        (( ++_agenix_generation ))
        mkdir -p "${cfg.secretsMountPoint}"
        chmod 0751 "${cfg.secretsMountPoint}"
        mkdir -p "${cfg.secretsMountPoint}/$_agenix_generation"
        chmod 0751 "${cfg.secretsMountPoint}/$_agenix_generation"
      '';

      setTruePath = secretType: ''
        ${
          if secretType.symlink then
            ''
              _truePath="${cfg.secretsMountPoint}/$_agenix_generation/${secretType.name}"
            ''
          else
            ''
              _truePath="${secretType.path}"
            ''
        }
      '';

      installSecret = secretType: ''
        ${setTruePath secretType}
        TMP_FILE="$_truePath.tmp"


        mkdir -p "$(dirname "$_truePath")"
        # shellcheck disable=SC2193,SC2050
        [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && mkdir -p "$(dirname "${secretType.path}")"
        (
          umask u=r,g=,o=
          test -f "${secretType.file}" || echo '[agenix] WARNING: encrypted file ${secretType.file} does not exist!'
          test -d "$(dirname "$TMP_FILE")" || echo "[agenix] WARNING: $(dirname "$TMP_FILE") does not exist!"
          LANG=C ${lib.getExe ageWrapperScript} decrypt -o "$TMP_FILE" "${secretType.file}"
        )
        chmod ${secretType.mode} "$TMP_FILE"
        mv -f "$TMP_FILE" "$_truePath"

        ${optionalString secretType.symlink ''
          # shellcheck disable=SC2193,SC2050
          [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && ln -sfT "${cfg.secretsDir}/${secretType.name}" "${secretType.path}"
        ''}
      '';

      loadSecret = secretType: ''
        export ${secretType.environmentName}=${secretType.path}
      '';

      cleanupAndLink = ''
        _agenix_generation="$(basename "$(readlink "${cfg.secretsDir}")" || echo 0)"
        (( ++_agenix_generation ))
        ln -sfT "${cfg.secretsMountPoint}/$_agenix_generation" "${cfg.secretsDir}"

        (( _agenix_generation > 1 )) && {
        rm -rf "${cfg.secretsMountPoint}/$(( _agenix_generation - 1 ))"
        }
      '';

      installSecrets = concatStringsSep "\n" (
        (map installSecret (builtins.attrValues cfg.secrets)) ++ [ cleanupAndLink ]
      );

      loadSecrets = concatStringsSep "\n" (
        map loadSecret (
          filter (s: (s ? environmentName && s.environmentName != null)) (builtins.attrValues cfg.secrets)
        )
      );

      secretType = types.submodule (
        {
          config,
          name,
          ...
        }:
        {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
              description = ''
                Name of the file used in ''${cfg.secretsDir}.
              '';
            };
            environmentName = mkOption {
              type = types.nullOr types.str;
              default = config.name;
              description = ''
                Name of the environment variable that may store this secret.
              '';
            };
            file = mkOption {
              type = types.path;
              description = ''
                Age file the secret is loaded from.
              '';
            };
            path = mkOption {
              type = types.str;
              default = "${cfg.secretsDir}/${config.name}";
              description = ''
                Path where the decrypted secret is installed.
              '';
            };
            mode = mkOption {
              type = types.str;
              default = "0400";
              description = ''
                Permissions mode of the decrypted secret in a format understood by chmod.
              '';
            };
            symlink = mkEnableOption "symlinking secrets to their destination" // {
              default = true;
            };
          };
        }
      );
      userDirectory =
        dir:
        let
          inherit (pkgs.stdenv.hostPlatform) isDarwin;
          baseDir =
            if isDarwin then "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)" else "\${XDG_RUNTIME_DIR}";
        in
        "${baseDir}/${dir}";

      userDirectoryDescription =
        dir:
        literalExpression ''
          "''${XDG_RUNTIME_DIR}"/''${dir} on linux or "$(getconf DARWIN_USER_TEMP_DIR)"/''${dir} on darwin.
        '';
    in
    {
      options.age = {
        package = mkPackageOption pkgs "age" { };

        extraPlugins = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = ''
            Extra age plugins which will be added to PATH
          '';
        };

        secrets = mkOption {
          type = types.attrsOf secretType;
          default = { };
          description = ''
            Attrset of secrets.
          '';
        };

        secretsDir = mkOption {
          type = types.str;
          default = userDirectory "agenix-devshell/${flakeName}";
          defaultText = userDirectoryDescription "agenix-devshell/${flakeName}";
          description = ''
            Folder where secrets are symlinked to.
          '';
        };

        secretsMountPoint = mkOption {
          default = userDirectory "agenix.d/${flakeName}";
          defaultText = userDirectoryDescription "agenix.d/${flakeName}";
          description = ''
            Where secrets are created before they are symlinked to ''${cfg.secretsDir}
          '';
        };

        identityPaths = mkOption {
          type =
            with types;
            let
              identityPathType = coercedTo path toString str;
            in
            listOf (
              # By coercing the old identityPathType into a canonical submodule of the form
              # ```
              # {
              #   identity = <identityPath>;
              #   pubkey = ...;
              # }
              # ```
              # we don't have to worry about it at a later stage.
              coercedTo identityPathType (p: if isAttrs p then p else { identity = p; }) (submodule {
                options = {
                  identity = mkOption { type = identityPathType; };
                  pubkey = mkOption {
                    type = nullOr (coercedTo path (x: if isPath x then readFile x else x) str);
                    default = null;
                  };
                };
              })
            );
          default = [
            "\${HOME}/.ssh/id_ed25519"
            "\${HOME}/.ssh/id_rsa"
          ];
          defaultText = literalExpression ''
            [
              "''${HOME}/.ssh/id_ed25519"
              "''${HOME}/.ssh/id_rsa"
            ]
          '';
          example = [
            ./secrets/my-public-yubikey-identity.txt
            {
              identity = ./password-encrypted-identity.pub;
              pubkey = "age1qyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqs3290gq";
            }
          ];
          description = ''
            Path to SSH keys / other age keys to be used as identities in age decryption.
          '';
        };
      };

      config = mkIf (cfg.secrets != { }) {
        packages = [
          cfg.package
        ];

        commands = [
          {
            help = "Encrypts/Decrypts a secret";
            name = "agenix-devshell";
            command = "exec ${lib.getExe ageWrapperScript} $@";
            category = "secret management";
          }
          {
            help = "Re-encrypt all secrets";
            name = "agenix-devshell-rekey";
            command = rekeyScript;
            category = "secret management";
          }
          {
            help = "Edits a secret";
            name = "agenix-devshell-edit";
            command = editScript;
            category = "secret management";
          }
        ];
        devshell.startup.agenix-devshell = lib.stringAfter [ "motd" ] ''
          ${newGeneration}
          ${installSecrets}
          ${loadSecrets}
        '';
      };
    };
}
