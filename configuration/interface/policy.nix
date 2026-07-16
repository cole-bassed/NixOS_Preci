{
  config,
  lib,
  mkArgs,
  ...
} @ args: let
  module = mkArgs args;
  cfg = config.${module.names.custom}.interface;
in {
  options.${module.names.custom}.interface = {
    backend = lib.mkOption {
      type = lib.types.str;
      description = "The active window manager/compositor.";
    };

    frontend = lib.mkOption {
      type = lib.types.str;
      description = "The active user interface layer/shell.";
    };

    protocol = lib.mkOption {
      type = lib.types.enum ["x11" "wayland"];
      default = "wayland";
      description = "System protocol targeted by the interface.";
    };
  };

  config = {
    # Dynamically resolve and enable the selected backend and frontend flat modules
    ${module.names.custom}.applications = {
      ${cfg.backend}.enable = true;
      ${cfg.frontend}.enable = true;
    };
  };
}
