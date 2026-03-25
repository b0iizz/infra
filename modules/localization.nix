{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      time.timeZone = lib.mkDefault "Europe/Berlin";

      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
      console = lib.mkDefault {
        font = "default8x16";
        keyMap = "de";
      };
    };
}
