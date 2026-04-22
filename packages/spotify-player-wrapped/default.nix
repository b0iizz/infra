let
  defaultSettings = fromTOML (builtins.readFile ./app.toml);
  defaultKeymapRaw = fromTOML (builtins.readFile ./keymap.toml);
  parseKeymap =
    lib: keymap:
    lib.pipe keymap [
      (builtins.getAttr "keymaps")
      (map (x: lib.nameValuePair x.key_sequence x.command))
      builtins.listToAttrs
    ];
in
{
  lib,
  formats,
  runCommand,
  makeWrapper,

  extraPackages ? [ ],

  spotify-player,

  settings ? defaultSettings,
  keymap ? (parseKeymap lib defaultKeymapRaw),
  keymap-defaults ? true,
  theme ? { },
  force-sixel-alacritty ? false,
  extraWrapperArgs ? [ ],
  ...
}:
let
  settingsFormat = formats.toml { };

  defaultKeymap = parseKeymap lib defaultKeymapRaw;
  clearKeymap = lib.mapAttrs (name: value: "None") defaultKeymap;
  baseKeymap = if keymap-defaults then { } else clearKeymap;

  formatKeymap = keymap: {
    keymaps = lib.mapAttrsToList (name: value: {
      key_sequence = name;
      command = value;
    }) keymap;
  };

  configHome =
    if (settings == defaultSettings && keymap == defaultKeymap && theme == { }) then
      null
    else
      runCommand "spotify-player-config" { } ''
        mkdir -p "$out"
        ln -s ${settingsFormat.generate "app.toml" (defaultSettings // settings)} "$out/app.toml"
        ${lib.optionalString (keymap != defaultKeymap)
          "ln -s ${
            settingsFormat.generate "keymap.toml" (formatKeymap (baseKeymap // keymap))
          } \"$out/keymap.toml\""
        }
        ${lib.optionalString (
          theme != { }
        ) "ln -s ${settingsFormat.generate "theme.toml" theme} \"$out/theme.toml\""}
      '';

  optionalWrapperArgs = [
    "--prefix PATH : ${lib.escapeShellArg (lib.makeBinPath extraPackages)}"
  ]
  ++ (lib.optional force-sixel-alacritty "--run ${lib.escapeShellArg "export TERM=$([[ $TERM -eq \"alacritty\" ]] && echo \"foot\" || echo \"$TERM\" )"}")
  ++ (lib.optional (
    configHome != null
  ) "--add-flags ${lib.escapeShellArg "--config-folder ${configHome}"}")
  ++ extraWrapperArgs;

  wrapperLines = lib.pipe optionalWrapperArgs [
    (map (arg: "\\\n  " + arg))
    lib.concatStrings
  ];

in
runCommand spotify-player.name
  {
    inherit (spotify-player) pname version;
    meta = {
      inherit (spotify-player.meta)
        description
        homepage
        license
        mainProgram
        ;
    };
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p "$out/bin"
    ln -s "${spotify-player}/share" "$out/share"
    makeWrapper ${lib.getExe' spotify-player "spotify_player"} "$out/bin/spotify_player" ${wrapperLines}
  ''
