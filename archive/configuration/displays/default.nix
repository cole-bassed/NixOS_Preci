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
              enable =
                mkEnableOption "display output"
                // {default = true;};

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
                  Display position input. May be semantic ("left", "right",
                  "top", "bottom", "center") or exact coordinates in "XxY" form.
                '';
              };

              layout = mkOption {
                type = submodule {
                  options = {
                    size = mkOption {
                      type = submodule {
                        options = {
                          width = mkOption {
                            type = int;
                            default = 0;
                            description = "Resolved display width in pixels.";
                          };

                          height = mkOption {
                            type = int;
                            default = 0;
                            description = "Resolved display height in pixels.";
                          };
                        };
                      };
                      default = {};
                      description = "Resolved display pixel size.";
                    };

                    position = mkOption {
                      type = submodule {
                        options = {
                          x = mkOption {
                            type = int;
                            default = 0;
                            description = "Resolved x coordinate in the compositor layout.";
                          };

                          y = mkOption {
                            type = int;
                            default = 0;
                            description = "Resolved y coordinate in the compositor layout.";
                          };
                        };
                      };
                      default = {};
                      description = "Resolved display position in the compositor layout.";
                    };
                  };
                };
                default = {};
                description = "Resolved compositor layout for this display.";
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

              primary =
                mkEnableOption "Whether this display is the primary output. Derived from API list order."
                // {default = false;};
            };
          };
        };
    }
  )
