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
              numlock = null;
            };
            touchpad = {
              tap = null;
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
            focus-ring.off = null;
            border = {
              width = 4;
              active-color = colors.base0D;
              inactive-color = colors.base03;
              urgent-color = colors.base08;
            };
          };

          binds = {
            "Mod+Shift+Numbersign".show-hotkey-overlay = null;

            "Mod+T" = {
              _attrs.hotkey-overlay-title = "Open Terminal (alacritty)";
              spawn = lib.getExe self'.packages.alacritty-wrapped;
            };
            "Mod+D" = {
              _attrs.hotkey-overlay-title = "Open Browser (librewolf)";
              spawn = lib.getExe self'.packages.librewolf-wrapped;
            };
            "Mod+G" = {
              _attrs.hotkey-overlay-title = "Open File Manager (yazi)";
              spawn = [
                (lib.getExe self'.packages.alacritty-wrapped)
                "-e"
                (lib.getExe self'.packages.yazi-wrapped)
              ];
            };
            "Mod+Space" = {
              _attrs.hotkey-overlay-title = "Open Launcher (noctalia)";
              spawn = [
                (lib.getExe self'.packages.noctalia-shell-wrapped)
                "ipc"
                "call"
                "launcher"
                "toggle"
              ];
            };

            "XF86AudioRaiseVolume" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            };
            "XF86AudioLowerVolume" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            };
            "XF86AudioMute" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "XF86AudioMicMute" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };

            "XF86AudioPlay" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "playerctl play-pause";
            };
            "XF86AudioStop" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "playerctl stop";
            };
            "XF86AudioPrev" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "playerctl previous";
            };
            "XF86AudioNext" = {
              _attrs.allow-when-locked = true;
              spawn-sh = "playerctl next";
            };

            "XF86MonBrightnessUp" = {
              _attrs.allow-when-locked = true;
              spawn = [
                "brightnesssctl"
                "--class=backlight"
                "set"
                "+10%"
              ];
            };
            "XF86MonBrightnessDown" = {
              _attrs.allow-when-locked = true;
              spawn = [
                "brightnessctl"
                "--class=backlight"
                "set"
                "10%-"
              ];
            };

            "Mod+O" = {
              _attrs.repeat = false;
              toggle-overview = null;
            };
            "Mod+Q" = {
              _attrs.repeat = false;
              close-window = null;
            };

            "Mod+Left".focus-column-left = null;
            "Mod+H".focus-column-left = null;
            "Mod+Down".focus-window-or-workspace-down = null;
            "Mod+J".focus-window-or-workspace-down = null;
            "Mod+Up".focus-window-or-workspace-up = null;
            "Mod+K".focus-window-or-workspace-up = null;
            "Mod+Right".focus-column-right = null;
            "Mod+L".focus-column-right = null;

            "Mod+Ctrl+Left".move-column-left = null;
            "Mod+Ctrl+H".move-column-left = null;
            "Mod+Ctrl+Down".move-window-down-or-to-workspace-down = null;
            "Mod+Ctrl+J".move-window-down-or-to-workspace-down = null;
            "Mod+Ctrl+Up".move-window-up-or-to-workspace-up = null;
            "Mod+Ctrl+K".move-window-up-or-to-workspace-up = null;
            "Mod+Ctrl+Right".move-column-right = null;
            "Mod+Ctrl+L".move-column-right = null;

            "Mod+Home".focus-column-first = null;
            "Mod+End".focus-column-last = null;
            "Mod+Ctrl+Home".focus-column-first = null;
            "Mod+Ctrl+End".focus-column-last = null;

            "Mod+Shift+Left".focus-monitor-left = null;
            "Mod+Shift+H".focus-monitor-left = null;
            "Mod+Shift+Down".focus-monitor-down = null;
            "Mod+Shift+J".focus-monitor-down = null;
            "Mod+Shift+Up".focus-monitor-up = null;
            "Mod+Shift+K".focus-monitor-up = null;
            "Mod+Shift+Right".focus-monitor-right = null;
            "Mod+Shift+L".focus-monitor-right = null;

            "Mod+Ctrl+Shift+Left".move-column-to-monitor-left = null;
            "Mod+Ctrl+Shift+H".move-column-to-monitor-left = null;
            "Mod+Ctrl+Shift+Down".move-column-to-monitor-down = null;
            "Mod+Ctrl+Shift+J".move-column-to-monitor-down = null;
            "Mod+Ctrl+Shift+Up".move-column-to-monitor-up = null;
            "Mod+Ctrl+Shift+K".move-column-to-monitor-up = null;
            "Mod+Ctrl+Shift+Right".move-column-to-monitor-right = null;
            "Mod+Ctrl+Shift+L".move-column-to-monitor-right = null;

            "Mod+Page_Down".focus-workspace-down = null;
            "Mod+Page_Up".focus-workspace-up = null;
            "Mod+U".focus-workspace-down = null;
            "Mod+I".focus-workspace-up = null;
            "Mod+Ctrl+Page_Down".move-column-to-workspace-down = null;
            "Mod+Ctrl+Page_Up".move-column-to-workspace-up = null;
            "Mod+Ctrl+U".move-column-to-workspace-down = null;
            "Mod+Ctrl+I".move-column-to-workspace-up = null;

            "Mod+Shift+Page_Down".move-workspace-down = null;
            "Mod+Shift+Page_Up".move-workspace-up = null;
            "Mod+Shift+U".move-workspace-down = null;
            "Mod+Shift+I".move-workspace-up = null;

            "Mod+WheelScrollDown" = {
              _attrs.cooldown-ms = 150;
              focus-workspace-down = null;
            };
            "Mod+WheelScrollUp" = {
              _attrs.cooldown-ms = 150;
              focus-workspace-up = null;
            };
            "Mod+Ctrl+WheelScrollDown" = {
              _attrs.cooldown-ms = 150;
              move-column-to-workspace-down = null;
            };
            "Mod+Ctrl+WheelScrollUp" = {
              _attrs.cooldown-ms = 150;
              move-column-to-workspace-up = null;
            };

            "Mod+WheelScrollRight".focus-column-right = null;
            "Mod+WheelScrollLeft".focus-column-left = null;
            "Mod+Ctrl+WheelScrollRight".move-column-right = null;
            "Mod+Ctrl+WheelScrollLeft".move-column-left = null;

            "Mod+Shift+WheelScrollDown" = {
              _attrs.cooldown-ms = 150;
              focus-column-right = null;
            };
            "Mod+Shift+WheelScrollUp" = {
              _attrs.cooldown-ms = 150;
              focus-column-left = null;
            };
            "Mod+Shift+Ctrl+WheelScrollDown" = {
              _attrs.cooldown-ms = 150;
              move-column-right = null;
            };
            "Mod+Shift+Ctrl+WheelScrollUp" = {
              _attrs.cooldown-ms = 150;
              move-column-left = null;
            };

            "Mod+Udiaeresis".consume-or-expel-window-left = null;
            "Mod+Plus".consume-or-expel-window-right = null;

            "Mod+Comma".consume-window-into-column = null;
            "Mod+Period".expel-window-from-column = null;

            "Mod+R".switch-preset-column-width = null;
            "Mod+Shift+R".switch-preset-window-height = null;
            "Mod+F".maximize-column = null;
            "Mod+Shift+F".fullscreen-window = null;

            "Mod+M".maximize-window-to-edges = null;
            "Mod+Ctrl+F".expand-column-to-available-width = null;
            "Mod+C".center-column = null;
            "Mod+Ctrl+C".center-visible-columns = null;

            "Mod+Ssharp".set-column-width = "-10%";
            "Mod+Dead_Acute".set-column-width = "+10%";
            "Mod+Shift+Ssharp".set-window-height = "-10%";
            "Mod+Shift+Dead_Acute".set-window-height = "+10%";

            "Mod+W".toggle-column-tabbed-display = null;

            "Print".screenshot = null;
            "Ctrl+Print".screenshot-screen = null;
            "Alt+Print".screenshot-window = null;

            "Mod+Escape" = {
              _attrs.allow-inhibiting = false;
              toggle-keyboard-shortcuts-inhibit = null;
            };

            "Mod+Shift+E".quit = null;
            "Ctrl+Alt+Delete".quit = null;

            "Mod+Shift+P".power-off-monitors = null;

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
