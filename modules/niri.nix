{
  self,
  inputs,
  config,
  ...
}:
{

  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        sddm
        yazi
      ];

      programs.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri-wrapped;
      };

      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      inherit (config.stylix.module { inherit pkgs; }) stylix;
      colors = config.stylix.colors.withHashtag;
    in
    {
      packages.niri-wrapped = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            [
              (lib.getExe self'.packages.noctalia-shell-wrapped)
            ]
            [
              (lib.getExe pkgs.swaybg)
              "--image"
              stylix.image
              "--mode"
              stylix.imageScalingMode
            ]
          ];

          cursor = {
            xcursor-theme = stylix.cursor.name;
            xcursor-size = stylix.cursor.size;

            hide-after-inactive-ms = 2500;
          };

          prefer-no-csd = true;

          input = {
            keyboard = {
              xkb.layout = "de";
              numlock = _: { };
            };
            touchpad = {
              tap = _: { };
            };
          };

          layout = {
            gaps = 16;
            preset-column-widths = [
              { proportion = 0.33; }
              { proportion = 0.5; }
              { proportion = 0.66; }
              { fixed = 1000; }
            ];
            default-column-width.proportion = 0.5;
            focus-ring.off = _: { };
            border = {
              width = 4;
              active-color = colors.base0D;
              inactive-color = colors.base03;
              urgent-color = colors.base08;
            };
          };

          binds = {
            "Mod+Shift+Numbersign".show-hotkey-overlay = _: { };

            "Mod+T" = _: {
              props.hotkey-overlay-title = "Open Terminal (alacritty)";
              content = {
                spawn = lib.getExe self'.packages.alacritty-wrapped;
              };
            };
            "Mod+D" = _: {
              props.hotkey-overlay-title = "Open Browser (librewolf)";
              content = {
                spawn = lib.getExe self'.packages.librewolf-wrapped;
              };
            };
            "Mod+G" = _: {
              props.hotkey-overlay-title = "Open File Manager (yazi)";
              content = {
                spawn = [
                  (lib.getExe self'.packages.alacritty-wrapped)
                  "-e"
                  (lib.getExe self'.packages.yazi-wrapped)
                ];
              };
            };
            "Mod+Space" = _: {
              props.hotkey-overlay-title = "Open Launcher (noctalia)";
              content = {
                spawn = [
                  (lib.getExe self'.packages.noctalia-shell-wrapped)
                  "ipc"
                  "call"
                  "launcher"
                  "toggle"
                ];
              };
            };

            "XF86AudioRaiseVolume" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
              };
            };
            "XF86AudioLowerVolume" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
              };
            };
            "XF86AudioMute" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              };
            };
            "XF86AudioMicMute" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
              };
            };

            "XF86AudioPlay" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "playerctl play-pause";
              };
            };
            "XF86AudioStop" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "playerctl stop";
              };
            };
            "XF86AudioPrev" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "playerctl previous";
              };
            };
            "XF86AudioNext" = _: {
              props.allow-when-locked = true;
              content = {
                spawn-sh = "playerctl next";
              };
            };

            "XF86MonBrightnessUp" = _: {
              props.allow-when-locked = true;
              content = {
                spawn = [
                  "brightnesssctl"
                  "--class=backlight"
                  "set"
                  "+10%"
                ];
              };
            };
            "XF86MonBrightnessDown" = _: {
              props.allow-when-locked = true;
              content = {
                spawn = [
                  "brightnessctl"
                  "--class=backlight"
                  "set"
                  "10%-"
                ];
              };
            };

            "Mod+O" = _: {
              props.repeat = false;
              content = {
                toggle-overview = _: { };
              };
            };
            "Mod+Q" = _: {
              props.repeat = false;
              content = {
                close-window = _: { };
              };
            };

            "Mod+Left".focus-column-left = _: { };
            "Mod+H".focus-column-left = _: { };
            "Mod+Down".focus-window-or-workspace-down = _: { };
            "Mod+J".focus-window-or-workspace-down = _: { };
            "Mod+Up".focus-window-or-workspace-up = _: { };
            "Mod+K".focus-window-or-workspace-up = _: { };
            "Mod+Right".focus-column-right = _: { };
            "Mod+L".focus-column-right = _: { };

            "Mod+Ctrl+Left".move-column-left = _: { };
            "Mod+Ctrl+H".move-column-left = _: { };
            "Mod+Ctrl+Down".move-window-down-or-to-workspace-down = _: { };
            "Mod+Ctrl+J".move-window-down-or-to-workspace-down = _: { };
            "Mod+Ctrl+Up".move-window-up-or-to-workspace-up = _: { };
            "Mod+Ctrl+K".move-window-up-or-to-workspace-up = _: { };
            "Mod+Ctrl+Right".move-column-right = _: { };
            "Mod+Ctrl+L".move-column-right = _: { };

            "Mod+Home".focus-column-first = _: { };
            "Mod+End".focus-column-last = _: { };
            "Mod+Ctrl+Home".focus-column-first = _: { };
            "Mod+Ctrl+End".focus-column-last = _: { };

            "Mod+Shift+Left".focus-monitor-left = _: { };
            "Mod+Shift+H".focus-monitor-left = _: { };
            "Mod+Shift+Down".focus-monitor-down = _: { };
            "Mod+Shift+J".focus-monitor-down = _: { };
            "Mod+Shift+Up".focus-monitor-up = _: { };
            "Mod+Shift+K".focus-monitor-up = _: { };
            "Mod+Shift+Right".focus-monitor-right = _: { };
            "Mod+Shift+L".focus-monitor-right = _: { };

            "Mod+Ctrl+Shift+Left".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+H".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+Down".move-column-to-monitor-down = _: { };
            "Mod+Ctrl+Shift+J".move-column-to-monitor-down = _: { };
            "Mod+Ctrl+Shift+Up".move-column-to-monitor-up = _: { };
            "Mod+Ctrl+Shift+K".move-column-to-monitor-up = _: { };
            "Mod+Ctrl+Shift+Right".move-column-to-monitor-right = _: { };
            "Mod+Ctrl+Shift+L".move-column-to-monitor-right = _: { };

            "Mod+Page_Down".focus-workspace-down = _: { };
            "Mod+Page_Up".focus-workspace-up = _: { };
            "Mod+U".focus-workspace-down = _: { };
            "Mod+I".focus-workspace-up = _: { };
            "Mod+Ctrl+Page_Down".move-column-to-workspace-down = _: { };
            "Mod+Ctrl+Page_Up".move-column-to-workspace-up = _: { };
            "Mod+Ctrl+U".move-column-to-workspace-down = _: { };
            "Mod+Ctrl+I".move-column-to-workspace-up = _: { };

            "Mod+Shift+Page_Down".move-workspace-down = _: { };
            "Mod+Shift+Page_Up".move-workspace-up = _: { };
            "Mod+Shift+U".move-workspace-down = _: { };
            "Mod+Shift+I".move-workspace-up = _: { };

            "Mod+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content = {
                focus-workspace-down = _: { };
              };
            };
            "Mod+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content = {
                focus-workspace-up = _: { };
              };
            };
            "Mod+Ctrl+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content = {
                move-column-to-workspace-down = _: { };
              };
            };
            "Mod+Ctrl+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content = {
                move-column-to-workspace-up = _: { };
              };
            };

            "Mod+WheelScrollRight".focus-column-right = _: { };
            "Mod+WheelScrollLeft".focus-column-left = _: { };
            "Mod+Ctrl+WheelScrollRight".move-column-right = _: { };
            "Mod+Ctrl+WheelScrollLeft".move-column-left = _: { };

            "Mod+Shift+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content = {
                focus-column-right = _: { };
              };
            };
            "Mod+Shift+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content = {
                focus-column-left = _: { };
              };
            };
            "Mod+Shift+Ctrl+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content = {
                move-column-right = _: { };
              };
            };
            "Mod+Shift+Ctrl+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content = {
                move-column-left = _: { };
              };
            };

            "Mod+Udiaeresis".consume-or-expel-window-left = _: { };
            "Mod+Plus".consume-or-expel-window-right = _: { };

            "Mod+Comma".consume-window-into-column = _: { };
            "Mod+Period".expel-window-from-column = _: { };

            "Mod+R".switch-preset-column-width = _: { };
            "Mod+Shift+R".switch-preset-window-height = _: { };
            "Mod+F".maximize-column = _: { };
            "Mod+Shift+F".fullscreen-window = _: { };

            "Mod+M".maximize-window-to-edges = _: { };
            "Mod+Ctrl+F".expand-column-to-available-width = _: { };
            "Mod+C".center-column = _: { };
            "Mod+Ctrl+C".center-visible-columns = _: { };

            "Mod+Ssharp".set-column-width = "-10%";
            "Mod+Dead_Acute".set-column-width = "+10%";
            "Mod+Shift+Ssharp".set-window-height = "-10%";
            "Mod+Shift+Dead_Acute".set-window-height = "+10%";

            "Mod+W".toggle-column-tabbed-display = _: { };

            "Print".screenshot = _: { };
            "Ctrl+Print".screenshot-screen = _: { };
            "Alt+Print".screenshot-window = _: { };

            "Mod+Escape" = _: {
              props.allow-inhibiting = false;
              content = {
                toggle-keyboard-shortcuts-inhibit = _: { };
              };
            };

            "Mod+Shift+E".quit = _: { };
            "Ctrl+Alt+Delete".quit = _: { };

            "Mod+Shift+P".power-off-monitors = _: { };

          }
          // (lib.foldl lib.mergeAttrs { } (
            lib.genList (
              i:
              let
                idx = i + 1;
              in
              {
                "Mod+${toString idx}".focus-workspace = idx;
                "Mod+Ctrl+${toString idx}".move-column-to-workspace = idx;
              }
            ) 9
          ));
        };

        suffixVar = [
          [
            "XCURSOR_PATH"
            ":"
            "${lib.makeSearchPath "share/icons" [ stylix.cursor.package ]}"
          ]
        ];
      };
    };
}
