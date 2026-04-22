{
  self,
  lib,
  config,
  ...
}:
{

  flake.modules.nixos.sddm =
    { pkgs, ... }:
    {
      services.displayManager.sddm = {
        wayland.enable = lib.mkDefault true;
        enable = true;
        theme = "sddm-astronaut-theme";
        extraPackages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-astronaut-styled
        ];
      };
      environment.systemPackages = [
        pkgs.kdePackages.qtmultimedia
        self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-astronaut-styled
      ];
    };

  perSystem =
    { pkgs, ... }:
    let
      inherit (config.stylix.module { inherit pkgs; }) stylix;
      fileType = lib.last (lib.splitString "." stylix.image);
    in
    {
      packages.sddm-astronaut-styled = (
        (pkgs.sddm-astronaut.override (
          with config.stylix.colors.withHashtag;
          {
            themeConfig = {
              ScreenWidth = "1920";
              ScreenHeight = "1080";
              ScreenPadding = "";

              Font = stylix.fonts.monospace.name;
              FontSize = stylix.fonts.sizes.desktop * 2;

              KeyboardSize = "0.4";

              RoundCorners = "20";

              Locale = "";
              # Locale for data and time format. I suggest leaving it blank.
              HourFormat = "HH:mm";
              # Default Locale.ShortFormat.
              DateFormat = "dddd d MMMM";
              # Default Locale.LongFormat.

              HeaderText = "";

              BackgroundPlaceholder = "";
              # Must be a relative path.
              # Background displayed before the actual background is loaded.
              # Use only if the background is a video, otherwise leave blank.
              # Connected with: Background.
              Background = "Backgrounds/stylix-background.${fileType}";
              # Must be a relative path.
              # Supports: png, jpg, jpeg, webp, gif, avi, mp4, mov, mkv, m4v, webm.
              BackgroundSpeed = "";
              # Default 1.0. Options: 0.0-10.0 (can go higher).
              # Speed of animated wallpaper.
              # Connected with: Background.
              PauseBackground = "";
              # Default false.
              # If set to true, stops playback of gifs. Works only with gifs.
              # Connected with: Background.
              DimBackground = "0.0";
              # Options: 0.0-1.0.
              # Connected with: DimBackgroundColor
              CropBackground = "true";
              # Default false.
              # Crop or fit background.
              # Connected with: BackgroundHorizontalAlignment and BackgroundVerticalAlignment dosn't work when set to true.
              BackgroundHorizontalAlignment = "center";
              # Default: center, Options: left, center, right.
              # Horizontal position of the background picture.
              # Connected with: CropBackground must be set to false.
              BackgroundVerticalAlignment = "center";
              # Horizontal position of the background picture.
              # Default: center, Options: bottom, center, top.
              # Connected with: CropBackground must be set to false.

              HeaderTextColor = base05;
              DateTextColor = base05;
              TimeTextColor = base05;

              FormBackgroundColor = base00;
              BackgroundColor = base00;
              DimBackgroundColor = base00;

              LoginFieldBackgroundColor = base01;
              PasswordFieldBackgroundColor = base01;
              LoginFieldTextColor = base05;
              PasswordFieldTextColor = base05;
              UserIconColor = base05;
              PasswordIconColor = base05;

              PlaceholderTextColor = base04;
              WarningColor = base0A;

              LoginButtonTextColor = base05;
              LoginButtonBackgroundColor = base01;
              SystemButtonsIconsColor = base04;
              SessionButtonTextColor = base04;
              VirtualKeyboardButtonTextColor = base04;

              DropdownTextColor = base05;
              DropdownSelectedBackgroundColor = base03;
              DropdownBackgroundColor = base0D;

              HighlightTextColor = base04;
              HighlightBackgroundColor = base0A;
              HighlightBorderColor = base08;

              HoverUserIconColor = base0C;
              HoverPasswordIconColor = base0C;
              HoverSystemButtonsIconsColor = base0C;
              HoverSessionButtonTextColor = base0C;
              HoverVirtualKeyboardButtonTextColor = base0C;

              PartialBlur = "false";
              # Default false.
              FullBlur = "";
              # Default false.
              # If you use FullBlur I recommend setting BlurMax to 64 and Blur to 1.0.
              BlurMax = "";
              # Default 48, Options: 2-64 (can go higher because depends on Blur).
              # Connected with: Blur.
              Blur = "";
              # Default 2.0, Options: 0.0-3.0 (without 3.0).
              # Connected with: BlurMax.

              HaveFormBackground = "false";
              # Form background is transparent if set to false.
              # Connected with: PartialBlur and BackgroundColor.
              FormPosition = "center";
              # Default: left, Options: left, center, right.

              VirtualKeyboardPosition = "center";
              # Default: left, Options: left, center, right.

              HideVirtualKeyboard = "true";
              HideSystemButtons = "false";
              HideLoginButton = "false";

              ForceLastUser = "true";
              # If set to true last successfully logged in user appeares automatically in the username field.
              PasswordFocus = "true";
              # Automaticaly focuses password field.
              HideCompletePassword = "true";
              # Hides the password while typing.
              AllowEmptyPassword = "false";
              # Enable login for users without a password.
              AllowUppercaseLettersInUsernames = "false"; # Do not change !!!
              BypassSystemButtonsChecks = "false";
              # Skips checking if sddm can perform shutdown, restart, suspend or hibernate, always displays all system buttons.
              RightToLeftLayout = "false";

            };
          }
        )).overrideAttrs
          (
            prev:
            let
              basePath = "$out/share/sddm/themes/sddm-astronaut-theme";
            in
            {
              installPhase = prev.installPhase + ''
                chmod u+w ${basePath}/Backgrounds/
                ln -sf ${stylix.image} ${basePath}/Backgrounds/stylix-background.${fileType}
              '';
            }
          )
      );
    };
}
