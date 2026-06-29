{
  lib,
  mkArgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  mkExtensionSettings = mapAttrs (_: pluginId: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
    installation_mode = "force_installed";
  });
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) opt;
  in {
    options = opt {
      policies = mkOption {
        type = attrs;
        default = {
          AutofillAddressEnabled = true;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          Preferences = {
            "browser.startup.homepage" = {
              Value = "about:blank";
              Status = "locked";
            };
            "browser.tabs.warnOnClose" = {
              Value = true;
              Status = "locked";
            };
          };
          ExtensionSettings = mkExtensionSettings {
            "wappalyzer@crunchlabz.com" = "wappalyzer";
            "{85860b32-02a8-431a-b2b1-40fbd64c9c69}" = "github-file-icons";
          };
        };
        description = "Firefox policy-template settings applied to Zen through policies.json.";
      };
    };
  };
}
