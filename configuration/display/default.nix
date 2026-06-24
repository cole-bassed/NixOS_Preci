{lix, ...} @ base: let
  inherit (lix.options) mkOption mkEnableOption;
  inherit (lix.types) asFloat nullOr int str submodule;
in
  lix.importModules (
    base
    // {
      base = ./.;
      extraArgs =
        (base.extraArgs or {})
        // {
          entry = submodule {
            options = {
              brand = mkOption {
                type = nullOr str;
                default = null;
                description = "Display/panel manufacturer.";
              };

              resolution = mkOption {
                type = nullOr str;
                default = null;
                description = "Native resolution, format \"WxH\".";
              };

              refreshRate = mkOption {
                type = nullOr asFloat;
                default = null;
                description = "Refresh rate in Hz.";
              };

              scale = mkOption {
                type = asFloat;
                default = 1.0;
                description = "Display scale factor.";
              };

              position = mkOption {
                type = nullOr str;
                default = null;
                description = ''
                  Display position. May be semantic ("left", "right", "top", "bottom", "center")
                  or exact coordinates in "XxY" form.
                '';
              };

              size = mkOption {
                type = nullOr asFloat;
                default = null;
                description = "Physical panel size, diagonal inches.";
              };

              priority = mkOption {
                type = int;
                default = 0;
                description = "Display ordering priority; derived from API list order.";
              };

              primary = mkEnableOption "Whether this display is the primary output. Derived from API list order.";
            };
          };
        };
    }
  )
