{
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  system.stateVersion = host.stateVersion;

  networking = {
    hostName = host.name;
    hostId = host.id or null;
  };

  time.timeZone = host.localization.timeZone or null;

  i18n.defaultLocale = host.localization.defaultLocale or "en_US.UTF-8";

  location = {
    latitude = host.localization.latitude or 0.0;
    longitude = host.localization.longitude or 0.0;
    provider = mkDefault (host.localization.locator or "manual");
  };

  nixpkgs = {
    hostPlatform = mkDefault host.system;
    config.allowUnfree = host.packages.allowUnfree or false;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.sessionVariables.DOTS = host.dots or null;
}
