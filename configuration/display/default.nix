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
              enable = mkEnableOption "display output" // {default = true;};

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
                description = "Position in the virtual layout, format \"XxY\".";
              };

              size = mkOption {
                type = nullOr asFloat;
                default = null;
                description = "Physical panel size, diagonal inches.";
              };

              priority = mkOption {
                type = int;
                default = 0;
                description = "Display ordering priority; 0 is primary.";
              };
            };
          };
        };
    }
  )
