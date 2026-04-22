{
  inputs,
  infuse-lib,
  config,
  ...
}:
let
  inherit (infuse-lib) infuse;
in
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (config.stylix.module { inherit pkgs; }) stylix;
    in
    {
      packages.noctalia-shell-wrapped = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;
        settings = infuse (builtins.fromJSON (builtins.readFile ./settings.json)).settings {

          bar.backgroundOpacity.__assign = stylix.opacity.desktop;
          bar.capsuleOpacity.__assign = stylix.opacity.desktop;
          ui.panelBackgroundOpacity.__assign = stylix.opacity.desktop;
          dock.backgroundOpacity.__assign = stylix.opacity.desktop;
          osd.backgroundOpacity.__assign = stylix.opacity.popups;
          notifications.backgroundOpacity.__assign = stylix.opacity.popups;

          ui.fontDefault.__assign = stylix.fonts.sansSerif.name;
          ui.fontFixed.__assign = stylix.fonts.monospace.name;
        };

        colors = with config.stylix.colors.withHashtag; {
          mPrimary = base0D;
          mOnPrimary = base00;
          mSecondary = base0E;
          mOnSecondary = base00;
          mTertiary = base0C;
          mOnTertiary = base00;
          mError = base08;
          mOnError = base00;
          mSurface = base00;
          mOnSurface = base05;
          mHover = base0C;
          mOnHover = base00;
          mSurfaceVariant = base01;
          mOnSurfaceVariant = base04;
          mOutline = base03;
          mShadow = base00;
        };
      };
    };
}
