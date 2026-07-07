{
  lix,
  top,
  host,
  path,
  registry,
  selection,
  ...
} @ args: let
  inherit (lix.attrsets) attrByPath attrNames;
  inherit (lix.lists) elemAt length;
  inherit (lix.modules) mkModules;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr attrs submodule;

  path' = path;

  # `selection host` returns an attrset keyed by backend name (see
  # registry.nix's `normalize`/`select`), not an ordered list — mirror
  # session.nix's `resolveBackends`/`backendNames` handling of the same shape.
  activeBackendNames = attrNames (selection host);
  primaryBackend =
    if length activeBackendNames > 0
    then elemAt activeBackendNames 0
    else null;
  primaryEnv =
    if primaryBackend != null
    then registry.${primaryBackend} or {}
    else {};
  registryFrontend = primaryEnv.frontend or null;
  isWayland = primaryEnv.protocol or null == "wayland";

  mkMod = {
    config,
    scope ? "core",
    pkgs,
    path ? path',
  }: let
    module = mkModuleArgs {inherit top config path scope pkgs;};
  in {
    inherit (module) opt cfg name;
    args = {inherit module;};
    # No per-child option stub declared here — frontend.selected is the
    # only real option; children just read it and contribute config.
    options = {};
    config = {};
  };

  inner = mkModules (args
    // {
      base = ./.;
      excludes = [];
      declareRegistry = false;
      childPath = path;
      extraArgs = {
        mkArgs = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
          osConfig ? config,
          defaults ? {},
        }: let
          mod = mkMod {inherit config path pkgs scope;};
          initiated = mod.args.module;
          evaluated = {inherit (mod) options config;};
          cfgOr = key:
            attrByPath
            ([top] ++ path ++ [key]) (defaults.${key} or null)
            osConfig;
        in
          initiated // {inherit initiated evaluated cfgOr;};
      };
    });

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {
      inherit config top scope;
      path = ["interface"];
    };
    inherit (mod) opt cfg;
  in {
    options = opt {
      frontend = mkOption {
        type = submodule {
          freeformType = attrs;
          options.selected = mkOption {
            type = nullOr (enum ["dank-material" "noctalia" "caelestia" "gnome" "plasma" "cosmic"]);
            default = host.interface.frontend or registryFrontend;
            description = "Graphical frontend layer for the selected desktop session backend.";
          };
        };
        default = {};
        description = "Graphical frontend configuration.";
      };
    };

    config.assertions = [
      {
        assertion = cfg.frontend.selected == null || primaryBackend != null;
        message = "interface.frontend requires an active interface.backend.";
      }
      {
        assertion = cfg.frontend.selected == null || isWayland;
        message = "The selected interface.frontend requires a Wayland session.";
      }
      {
        assertion = cfg.frontend.selected == null || cfg.frontend.selected == registryFrontend;
        message = "interface.frontend.selected (${toString cfg.frontend.selected}) doesn't match the frontend the registry declares for '${toString primaryBackend}' (${toString registryFrontend}).";
      }
    ];
  };
in {
  core.imports = (inner.imports or []) ++ [(mk "core")];
  home.imports = (inner.home-manager.sharedModules or []) ++ [(mk "home")];
}
