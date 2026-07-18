{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.modules) mkProgramToggle;

  # 1. Let mkProgramToggle build the standard framework attributes and options first
  baseToggle = mkProgramToggle {
    inherit top path;
  };
in
  baseToggle
  // {
    # 2. Intercept and replace the core module method with our customized logic
    core = {
      config,
      pkgs,
      options,
      ...
    }: let
      # Reconstruct the macro's environment arguments
      mod = lix.modules.mkModuleArgs {inherit config top path pkgs options;} // {scope = "core";};
      cfg = config.${top}.applications.dms-greeter or {};
    in {
      # Keep the normal framework options intact
      options = mod.opt mod.app;

      # Now we have a real config engine block to mount system services!
      config = {
        services.displayManager.dms-greeter = {
          enable = cfg.enable or false;
          package = cfg.package;
        };
      };
    };
  }
