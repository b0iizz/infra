{
  inputs,
  config,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (config.stylix.module { inherit pkgs; }) stylix;
    in
    {
      packages.alacritty-wrapped = inputs.wrapper-modules.wrappers.alacritty.wrap {
        inherit pkgs;

        package = pkgs.alacritty-graphics;

        settings = {
          colors = with config.stylix.colors.withHashtag; {
            primary = {
              foreground = base05;
              background = base00;
              bright_foreground = base07;
            };
            selection = {
              text = base05;
              background = base02;
            };
            cursor = {
              text = base00;
              cursor = base05;
            };
            normal = {
              black = base00;
              white = base05;
              inherit
                red
                green
                yellow
                blue
                magenta
                cyan
                ;
            };
            bright = {
              black = base03;
              white = base07;
              red = bright-red;
              green = bright-green;
              yellow = bright-yellow;
              blue = bright-blue;
              magenta = bright-magenta;
              cyan = bright-cyan;
            };
          };
          font = {
            normal = {
              family = stylix.fonts.monospace.name;
              style = "Regular";
            };
            size = stylix.fonts.sizes.terminal;
          };
          window.opacity = stylix.opacity.terminal;
        };
      };
    };
}
