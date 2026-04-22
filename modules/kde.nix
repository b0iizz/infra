{ self, ... }:
{
  flake.modules.nixos.kde = {
    imports = [ self.modules.nixos.sddm ];

    services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.desktopManager.plasma6.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "de";
      variant = "";
    };

  };
}
