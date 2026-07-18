# configuration/interface/default.nix
#
# This module is now PURE ORCHESTRATION between backends -- it no longer
# defines any backend's own options or config. That responsibility moved
# to each backend's own self-sufficient module
# (configuration/applications/{hyprland,niri,mango}/default.nix), which
# calls lix.modules.mkBackendOptions directly.
#
# What stays here: resolving which backend is primary/secondary/tertiary
# for a given host+user (via lix.interface.primaryOf/secondaryOf/
# tertiaryOf, reading the SAME api.applications.registry that backend
# modules themselves read -- see libraries/api/interface.nix), and
# exposing that resolution as read-only `dots.interface.{session,
# frontend,greeter,protocol,primary,secondary,tertiary}` options for
# other modules (displayManager selection, etc.) to consume.
{
  lix,
  api,
  top,
  host,
  ...
} @ args: let
  inherit (lix.options) mkOption;
  inherit (lix.types) isString nullAny nullStr;

  mkModule = scope: {config, ...}: let
    mod = lix.modules.mkModuleArgs (args // {inherit config scope;});
    inherit (mod) get set;
    inherit (get) user;

    primary = api.interface.primaryOf {inherit user host;};
    secondary = api.interface.secondaryOf {inherit user host;};
    tertiary = api.interface.tertiaryOf {inherit user host;};

    resolveAppName = name: api.applications.aliases.${name} or name;

    inflate = entry:
      if entry == null
      then null
      else let
        rawName =
          if isString entry
          then entry
          else entry.name or (throw "interface: cannot resolve application name from ${builtins.toJSON entry}");
        name = resolveAppName rawName;
        registryEntry =
          api.applications.registry.${name}
          or (throw "interface: '${name}' (resolved from '${rawName}') not found in dots.applications.registry");
        liveConfig = config.${top}.applications.${name} or {};
      in
        registryEntry // liveConfig // {inherit name;};
  in {
    options = set.opt {
      session = mkOption {
        type = nullStr;
        default = primary.name or null;
        description = "Name of the primary session, for display-manager configuration.";
      };
      frontend = mkOption {
        type = nullAny;
        default = inflate (primary.frontend or null);
        description = "Fully-resolved frontend application entry for the primary session.";
      };
      greeter = mkOption {
        type = nullAny;
        default = inflate (primary.greeter or null);
        description = "Fully-resolved greeter application entry for the primary session.";
      };
      protocol = mkOption {
        type = nullAny;
        default = let
          proto = primary.protocol or null;
        in
          if proto == null
          then null
          else {
            name = proto;
            packages = []; # TODO: resolve via protocol package map (e.g. xwayland-satellite for wayland when needsXwaylandSatellite)
          };
        description = "Display protocol of the primary session, as { name; packages; }.";
      };

      primary = mkOption {
        type = nullAny;
        default =
          primary
          // {
            frontend = inflate (primary.frontend or null);
            greeter = inflate (primary.greeter or null);
          };
        description = "The primary/default resolved interface session.";
      };
      secondary = mkOption {
        type = nullAny;
        default =
          if secondary == null
          then null
          else
            secondary
            // {
              frontend = inflate (secondary.frontend or null);
              greeter = inflate (secondary.greeter or null);
            };
        description = "The secondary resolved interface session, if any.";
      };
      tertiary = mkOption {
        type = nullAny;
        default =
          if tertiary == null
          then null
          else
            tertiary
            // {
              frontend = inflate (tertiary.frontend or null);
              greeter = inflate (tertiary.greeter or null);
            };
        description = "The tertiary resolved interface session, if any.";
      };
    };

    config = {};
  };
in {
  core.imports = [(mkModule "core")];
  home.imports = [(mkModule "home")];
}
