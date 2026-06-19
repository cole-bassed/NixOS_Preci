{
  inputs,
  lib,
  pkgs,
  mkArgs,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg;

    selectedUnwrappedPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}."${cfg.channel}-unwrapped";
  in {
    config = mkIf cfg.enable {
      programs.zen-browser = {
        enable = mkDefault true;
        setAsDefaultBrowser = mkDefault cfg.setAsDefaultBrowser;
        policies = mkDefault cfg.policies;
        nativeMessagingHosts = mkDefault cfg.nativeMessagingHosts;
        unwrappedPackage = mkDefault selectedUnwrappedPackage;

        profiles.${cfg.profile.name} = {
          settings = mkDefault cfg.profile.settings;
          mods = mkDefault cfg.profile.mods;
          search = mkDefault cfg.profile.search;
          bookmarks = mkDefault cfg.profile.bookmarks;
          containersForce = mkDefault cfg.profile.containersForce;
          containers = mkDefault cfg.profile.containers;
          spacesForce = mkDefault cfg.profile.spacesForce;
          spaces = mkDefault cfg.profile.spaces;
          pinsForce = mkDefault cfg.profile.pinsForce;
          pinsForceAction = mkDefault cfg.profile.pinsForceAction;
          pins = mkDefault cfg.profile.pins;
          joinedTabs = mkDefault cfg.profile.joinedTabs;
          keyboardShortcutsVersion = mkDefault cfg.profile.keyboardShortcutsVersion;
          keyboardShortcuts = mkDefault cfg.profile.keyboardShortcuts;
          userChrome = mkDefault cfg.profile.userChrome;
        };
      };
    };
  };
}
