{
  config,
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault;
  invalid = 999.999;
  longitude = host.localization.longitude or invalid;
  latitude = host.localization.latitude or invalid;
  provider =
    if longitude == invalid || latitude == invalid
    then "geoclue"
    else host.localization.locator or "manual";
in {
  system.stateVersion = host.stateVersion;

  networking = {
    hostName = host.name;
    hostId = host.id or null;
  };

  time.timeZone = host.localization.timeZone or null;

  i18n.defaultLocale = host.localization.defaultLocale or "en_US.UTF-8";

  location = {
    inherit latitude longitude;
    provider = mkDefault (
      if longitude == 0.0 && latitude == 0.0
      then "geoclue"
      else provider
    );
  };

  nixpkgs = {
    hostPlatform = mkDefault host.system;
    config.allowUnfree = host.packages.allowUnfree or false;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.sessionVariables.DOTS = host.dots or null;
}
