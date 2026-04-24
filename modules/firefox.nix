{
  slib,
  self,
  config,
  ...
}:
let
  inherit (config.stylix) colors;
in
{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.stylix.module { inherit pkgs; }) stylix;
      wrapperConfig = {

        extraPolicies = {
          #AppAutoUpdate = true;
          #AppUpdatePin
          #AppUpdateURL
          #BackgroundAppUpdate
          DisableAppUpdate = true;
          #ManualAppUpdateOnly

          #Authentication
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          OfferToSaveLogins = false;
          #OfferToSaveLoginsDefault = false;
          PasswordManagerEnabled = false;
          PasswordManagerExceptions = [ ];
          #PrimaryPassword
          DisableMasterPasswordCreation = true;
          DisablePasswordReveal = false;

          AllowFileSelectionDialogs = true;
          DefaultDownloadDirectory = "\${home}/Downloads";
          DownloadDirectory = "\${home}/Downloads";
          DisableBuiltinPDFViewer = false;
          PromptForDownloadLocation = false;
          StartDownloadsInTempDirectory = false;
          ExemptDomainFileTypePairsFromFileTypeDownloadWarnings = [ ];

          PDFjs = {
            Enable = true;
            EnablePermissions = false;
          };
          PrintingEnabled = true;
          UseSystemPrintDialog = false;
          #AutoLaunchProtocolsFromOrigins
          Handlers = {
            "mimeTypes" = { };
            "schemes" = { };
            "extensions" = { };
          };
          BlockAboutAddons = false;
          BlockAboutConfig = false;
          BlockAboutProfiles = false;
          BlockAboutSupport = false;

          #Bookmarks
          #ManagedBookmarks
          NoDefaultBookmarks = true;

          EncryptedMediaExtensions = {
            Enabled = true;
            Locked = true;
          };
          PictureInPicture = {
            Enabled = false;
            Locked = true;
          };

          DisableEncryptedClientHello = false;
          DNSOverHTTPS = {
            Enabled = true;
            ProviderURL = "https://doh.ffmuc.net/dns-query";
            Locked = true;
            ExcludedDomains = [ ];
            Fallback = true;
          };
          NetworkPrediction = false;
          GoToIntranetSiteForSingleWordEntryInAddressBar = false;

          HttpAllowlist = [ ];
          HttpsOnlyMode = "force_enabled";

          Certificates = {
            ImportEnterpriseRoots = true;
            #Install = [ filename.der filename2.pem ];
          };
          #Proxy
          #SecurityDevices
          #SSLVersionMax
          #SSLVersionMin
          DisabledCiphers = { };
          PostQuantumKeyAgreementEnabled = true;

          #Containers = { Default = [ name = "Default"; icon = "pet"; color = "green"; ]; };

          SearchBar = "unified";
          SearchEngines = {
            Default = "DuckDuckGo (custom)";
            Add = [
              {
                Name = "DuckDuckGo (custom)";
                URLTemplate =
                  with colors;
                  "https://duckduckgo.com/?kaj=m&kbg=-1&kbe=0&kbi=1&kbj=1&kp=-2&kav=1&k1=-1&kt=${lib.escapeURL stylix.fonts.monospace.name}&kae=d&k7=${base00}&kj=${base01}&k9=${base05}&kaa=${base04}&k8=${base05}&kx=${base05}&k21=${base01}&q={searchTerms}";
                SuggestURLTemplate = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
                Method = "GET";
                Alias = "ddgc";
              }
              {
                Name = "Noogle Dev";
                URLTemplate = "https://noogle.dev/q?term={searchTerms}";
                Method = "GET";
                Alias = "noo";
              }
              {
                Name = "Nixpkgs Search";
                URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
                Method = "GET";
                Alias = "pkgs";
              }
              {
                Name = "Nixos Options Search";
                URLTemplate = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
                Method = "GET";
                Alias = "options";
              }
            ];
            Remove = [
              "Google"
              "DuckDuckGo"
              "Bing"
              "Perplexity"
              "Wikipedia (en)"
            ];
            PreventInstalls = true;
          };
          SearchSuggestEnabled = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          NewTabPage = true;
          FirefoxHome = {
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            Stories = false;
            SponsoredPocket = false;
            SponsoredStories = false;
            Snippets = false;
            Locked = true;
          };
          Homepage = {
            URL = "about:blank";
            Locked = true;
            Additional = [ ];
            StartPage = "none";
          };
          CaptivePortal = true;
          DisableDeveloperTools = false;

          PopupBlocking = {
            Allow = [ ];
            Default = false;
            Locked = true;
          };

          HardwareAcceleration = true;

          TranslateEnabled = true;
          RequestedLocales = [
            "de"
            "en-US"
          ];

          #SanitizeOnShutdown = true;
          SanitizeOnShutdown = {
            Cache = true;
            Cookies = true;
            FormData = true;
            Locked = true;
          };

          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            FirefoxLabs = false;
            Locked = true;
          };

          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
          };

          DisableFeedbackCommands = true;

          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DontCheckDefaultBrowser = true;
          DisablePocket = true;

          DisableFirefoxAccounts = true;
          DisableFirefoxScreenshots = false;
          DisableForgetButton = false;
          DisableFormHistory = true;
          DisablePrivateBrowsing = false;
          PrivateBrowsingModeAvailability = 0;
          DisableProfileImport = true;
          DisableProfileRefresh = true;

          DisableSafeMode = false;
          DisableSecurityBypass = {
            InvalidCertificate = false;
            SafeBrowsing = false;
          };

          DisableSetDesktopBackground = true;
          DisableSystemAddonUpdate = false;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "never";
          ShowHomeButton = false;
          SkipTermsOfUse = true;
          #SupportMenu

          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
            SuspectedFingerprinting = true;
            Exceptions = [ ];
          };
          #ContentAnalysis
          Cookies = {
            Allow = [ ];
            AllowSession = [ ];
            Block = [ ];
            Locked = true;
            Behavior = "reject-tracker";
            BehaviorPrivateBrowsing = "reject";
          };
          LegacySameSiteCookieBehaviorEnabled = false;
          LegacySameSiteCookieBehaviorEnabledForDomainList = [ ];
          LocalFileLinks = [ ];
          WebsiteFilter = {
            Block = [ ];
            Exceptions = [ ];
          };
          #Permissions = {};

          InstallAddonsPermission = {
            Allow = [ ];
            Default = false;
          };
          ExtensionUpdate = false;
        };

        extraPrefs = ''
          // Show more ssl cert infos
          lockPref("security.identityblock.show_extended_validation", true);
        '';
      };
    in
    {
      packages.librewolf-wrapped = pkgs.wrapFirefox pkgs.librewolf-unwrapped (
        slib.infuse wrapperConfig {
          nixExtensions.__default = [ ];
          nixExtensions.__append = [
            (pkgs.fetchFirefoxAddon {
              name = "ublock"; # Has to be unique!
              url = "https://addons.mozilla.org/firefox/downloads/file/4629131/ublock_origin-1.68.0.xpi";
              hash = "sha256-XK9KvaSUAYhBIioSFWkZu92MrYKng8OMNrIt1kJwQxU=";
            })
            (pkgs.fetchFirefoxAddon {
              name = "bitwarden"; # Has to be unique!
              url = "https://addons.mozilla.org/firefox/downloads/file/4664623/bitwarden_password_manager-2025.12.1.xpi";
              hash = "sha256-p6Ej7uTkD92K98DGckNzHdzDeuFJjPKCiZX0kFYAxR8=";
            })
          ];
        }
      );
      packages.firefox-wrapped = pkgs.wrapFirefox pkgs.firefox-unwrapped wrapperConfig;
    };

  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      programs.firefox.package =
        lib.mkDefault
          self.packages.${pkgs.stdenv.hostPlatform.system}.librewolf-wrapped;
    };
}
