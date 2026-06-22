{
  lix,
  top,
  host,
  config,
  ...
}: let
  inherit (lix.attrsets) removeEmpty;
  inherit (lix.options) mkOption;
  inherit (lix.types) str nullOr float enum;
  mod = "localization";
  src = host.${mod} or {};

  #? One options declaration, reused for both `core` and `home`
  #  scopes below -- they are separate module-system evaluations
  #  (NixOS vs home-manager), so each needs its own copy of the
  #  option tree, but the shape and defaults are identical.
  options.${top}.${mod} = {
    #? Schema S3
    latitude = mkOption {
      type = nullOr float;
      default = src.latitude or null;
      description = "Decimal degrees, -90 to 90. Negative = South.";
    };

    longitude = mkOption {
      type = nullOr float;
      default = src.longitude or null;
      description = "Decimal degrees, -180 to 180. Negative = West.";
    };

    city = mkOption {
      type = nullOr str;
      default = src.city or null;
      description = "Human-readable location string, for display only.";
    };

    locator = mkOption {
      type = enum ["geoclue2" "manual" "networkmanager"];
      default = src.locator or "geoclue2";
      description = "Location provider backend.";
    };

    #? Required per schema S3. No default supplied here when the
    #  host file doesn't set it -- a host that omits `timeZone`
    #  entirely (and no other module sets
    #  `${top}.localization.timeZone` directly) will fail at
    #  evaluation with the module system's own "value is required
    #  but not set" error, which is the correct failure mode for a
    #  required field.
    timeZone = mkOption (
      {
        type = str;
        description = "tzdata identifier, e.g. \"America/Jamaica\".";
      }
      // (
        if (src.timeZone or null) != null
        then {default = src.timeZone;}
        else {}
      )
    );

    defaultLocale = mkOption (
      {
        type = str;
        description = "glibc locale string, e.g. \"en_US.UTF-8\".";
      }
      // (
        if (src.defaultLocale or null) != null
        then {default = src.defaultLocale;}
        else {}
      )
    );
  };

  #? `core` (NixOS) sets geoclue location, the system timezone, and
  #  the system default locale. `home` (home-manager) only sets the
  #  user-facing language base -- there is no equivalent of
  #  `location`/`time.timeZone` at that scope.
  mk = scope: {
    inherit options;

    config = let
      #? Read back the RESOLVED option values for *this scope's own*
      #  config tree, not raw `host.*` -- so a value set directly on
      #  `${top}.localization.*` (with no `host.nix` entry at all)
      #  behaves identically to one sourced from the host file.
      cfg = config.${top}.${mod};
    in
      if scope == "core"
      then {
        location = removeEmpty {
          inherit (cfg) latitude longitude;
          provider = cfg.locator;
        };
        time.timeZone = cfg.timeZone;
        i18n.defaultLocale = cfg.defaultLocale;
      }
      else {home.language.base = cfg.defaultLocale;};
  };
in {
  core = mk "core";
  home = mk "home";
}
