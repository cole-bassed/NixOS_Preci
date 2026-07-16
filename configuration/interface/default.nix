# {lix, ...} @ args: let
#   inherit (lix.modules) mkModules mkModuleArgs;
#   moduleArgs = {
#     inherit extraArgs;
#     base = ./.;
#     excludes = [
#       "backend"
#       "frontend"
#       "protocol"
#       "session"
#     ];
#   };
#   extraArgs = {
#     mkArgs = {
#       config,
#       osConfig ? {},
#       options ? {},
#       path,
#       scope ? "core",
#       pkgs ? {},
#     }:
#       mkModuleArgs {
#         inherit
#           config
#           options
#           osConfig
#           path
#           pkgs
#           scope
#           ;
#       };
#   };
# in
#   mkModules (args // moduleArgs)
{
  config,
  lib,
  ...
}: let
  cfg = config.dots.interface;
in {
  options.dots.interface = {
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
    # Automatically enable the selected backend and frontend flat modules
    dots.applications.${cfg.backend}.enable = true;
    dots.applications.${cfg.frontend}.enable = true;
  };
}
