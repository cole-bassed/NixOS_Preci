{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.modules) mkProgramToggle;
in
  mkProgramToggle {
    inherit top path;

    # This hooks it straight into the same home-manager execution layout
    # or system-level configuration properties you'll need for DM styling.
    extraOptions = mod: let
      inherit (mod) get;
      name = get.names.name;
    in {
      # Add any dms-greeter explicit flags here if needed later
    };

    extraCoreConfig = mod: let
      inherit (mod) cfg;
    in {
      # This is where your display manager/greeter service integration pairs.
      # If your system uses greetd, lightdm, or a custom DM block:
      # services.displayManager.ly.enable = cfg.enable or false;
    };
  }
