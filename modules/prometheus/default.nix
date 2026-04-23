{
  self,
  inputs,
  config,
  ...
}:
{
  flake.nixosConfigurations = config.builders.mkNixosConfig {
    hostName = "prometheus";
    module = self.modules.nixos.prometheus;
  };

  flake.modules.devshell.unlocked = {
    age.secrets.prometheus-hostkey = {
      environmentName = config.flake.nixosConfigurations.prometheus.config.installer.hostKeyFileEnvVar;
      file = "${self}/secrets/manual/prometheus-hostkey.age";
    };
  };

  flake.modules.nixos.prometheus =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = with self.modules.nixos; [
        inputs.nixos-hardware.nixosModules.framework-13th-gen-intel
        host-pc
        niri
      ];

      age.rekey.hostPubkey = lib.trim (builtins.readFile ./host-key.pub);

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      hardware.facter.reportPath = ./facter.json;
      hardware.fw-fanctrl.enable = true;
      services.hardware.bolt.enable = true;

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Enable networking
      networking.networkmanager = {
        enable = true;
        plugins = with pkgs; [
          networkmanager-openvpn
        ];
      };

      # Set your time zone.
      time.timeZone = "Europe/Berlin";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };

      # Enable the X11 windowing system.
      # You can disable this if you're only using the Wayland session.
      # Configure console keymap
      console.keyMap = "de";

      services.gvfs.enable = true;

      # Enable CUPS to print documents.
      services.printing = {
        enable = true;
        drivers = with pkgs; [
          epson-escpr2
          epson-escpr
        ];
      };
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
      };

      # Enable touchpad support (enabled default in most desktopManager).
      # services.xserver.libinput.enable = true;

      # Install firefox.
      programs.firefox.enable = true;

      programs.localsend.enable = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        package = pkgs.steam.override (prev: {
          extraArgs = (prev.extraArgs or "") + " -system-composer";
        });
      };

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        #  wget
        git
        glib
        libreoffice-fresh
        self.packages.${stdenv.hostPlatform.system}.spotify-player-wrapped
        eduvpn-client
      ];

      programs.nix-ld.enable = true;
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "26.05"; # Did you read the comment?

    };
}
