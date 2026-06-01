{
  lix,
  host,
  ...
}: let
  inherit (lix.predicates) isValidGeoCoords;
  inherit (lix.debug) warnWithContext;

  location = let
    isValid = isValidGeoCoords {inherit latitude longitude;};
    _warn = warnWithContext {
      name = "localization";
      assertion = isValid;
      message = "invalid coordinates (${toString latitude}, ${toString longitude}); falling back to geoclue";
      context = "evaluating host localization for ${host.name or "unknown"}";
    };
    invalid = 999.0;
    longitude = host.localization.longitude or invalid;
    latitude = host.localization.latitude  or invalid;
    provider =
      if _warn && isValid
      then host.localization.locator or "manual"
      else "geoclue";
  in {inherit latitude longitude provider;};
in {inherit location;}
