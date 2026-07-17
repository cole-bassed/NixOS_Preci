{
  config, # This should not be imported here (this is core when this wone file should define both)
  lix,
  mkArgs,
  ...
} @ args: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) str enum nullOr;
  module = mkArgs args; # TODO: This is wrong, and it changes the shape/function of mkModuleArgs
  cfg = config.${module.names.custom}.interface; # TODO: This is wrong, we should be using mkModuleArgs
  # inherit (module.get) cfg;
in {
  options.${module.names.custom}.interface = {
    backend = mkOption {
      type = nullOr str;
      default = null;
      description = "The active window manager/compositor.";
    };

    frontend = mkOption {
      type = nullOr str;
      default = null;
      description = "The active user interface layer/shell.";
    };

    protocol = mkOption {
      type = enum ["x11" "wayland"];
      default = "wayland";
      description = "System protocol targeted by the interface.";
    };
  };

  config = mkIf (cfg.backend != null && cfg.frontend != null) {
    ${module.names.custom}.applications = {
      ${cfg.backend}.enable = true;
      ${cfg.frontend}.enable = true;
    };
  };
}
