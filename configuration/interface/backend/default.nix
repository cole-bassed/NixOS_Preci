{
  lix,
  top,
  host,
  path,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) asAttrs namesOf valuesOf;
  inherit (lix.ingestion) importModules;
  inherit (lix.lists) concatMap elem;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) enum listOf;

  setOf = list: namesOf (asAttrs list);
  getUI = base: (base.interface or {}).backend or {};
  collect = field: specs: setOf (concatMap (spec: spec.${field} or []) specs);
  merge = specs: {
    managers = collect "managers" specs;
    desktops = collect "desktops" specs;
  };

  spec = let
    host' = getUI host;
    users = map getUI (valuesOf (getInteractiveUsers host));
    managers = {
      x11 = ["awesome" "i3" "qtile" "xmonad"];
      wayland = ["hyprland" "labwc" "mango" "niri" "river" "sway" "wayfire"];
    };
    desktops = {
      x11 = ["cinnamon" "xfce"];
      wayland = ["gnome" "plasma"];
    };
  in {
    inherit managers desktops;
    all = {
      managers = with managers; x11 ++ wayland;
      desktops = with desktops; x11 ++ wayland;
    };
    core = merge ([host'] ++ users);
    home = user: merge [host' (getUI user)];
  };

  opts = preset: {
    managers = mkOption {
      type = listOf (enum spec.all.managers);
      default = preset.managers;
      description = "Enabled standalone compositors/window managers.";
    };
    desktops = mkOption {
      type = listOf (enum spec.all.desktops);
      default = preset.desktops;
      description = "Enabled full desktop environments.";
    };
  };

  mkArgs = config: scope:
    mkModuleArgs {inherit config top path scope;};
in let
  inner = importModules (args
    // {
      base = ./.;
      path = path;
      extraArgs = {
        mkArgs = {
          path,
          config,
          scope ? "core",
          extra ? {},
        }:
          mkModuleArgs ({inherit config top path scope;} // extra);
        mkEnable = {
          name,
          prettyName ? name,
          config,
          scope,
        }:
          mkEnable {
            description = "${prettyName} compositor";
            default = elem name ((config.${top}.interface.managers or []) ++ []);
            inherit name scope;
          };
        mkUWSM = {
          name,
          prettyName ? name,
          bin ? name,
        }: {
          inherit prettyName;
          comment = "${prettyName} compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/${bin}";
        };
      };
    });
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) opt;
  in {
    imports = inner.imports or [];
    options = opt (opts spec.core);
    config = {};
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((mkArgs config "home")) opt;
  in {
    imports = inner.home-manager.sharedModules or [];
    options = opt (opts (spec.home user));
    config = {};
  };
}
# lix.importModules (args
#   // {
#     base = ./.;
#     path = path;
#     extraArgs = {
#       mkArgs = {
#         path,
#         config,
#         scope ? "core",
#         extra ? {},
#       }:
#         mkModuleArgs ({inherit config top path scope;} // extra);
#       mkEnable = {
#         name,
#         prettyName ? name,
#         config,
#         scope,
#       }:
#         mkEnable {
#           description = "${prettyName} compositor";
#           default = elem name ((config.${top}.interface.managers or []) ++ []); # TODO:  This is wrong, it should be based on if host or user api wants it (elem name (host.interface.managers or (user.interface.managers or [])))
#           inherit name scope;
#         };
#       mkUWSM = {
#         name,
#         prettyName ? name,
#         bin ? name,
#       }: {
#         inherit prettyName;
#         comment = "${prettyName} compositor managed by UWSM";
#         binPath = "/run/current-system/sw/bin/${bin}";
#       };
#     };
#   })
# // {
#   core = {config, ...}: let
#     inherit ((mkArgs config "core")) opt;
#   in {
#     options = opt (opts spec.core);
#     config = {};
#   };
#   home = {
#     config,
#     user ? {},
#     ...
#   }: let
#     inherit ((mkArgs config "home")) opt;
#   in {
#     options = opt (opts (spec.home user));
#     config = {};
#   };
# }
