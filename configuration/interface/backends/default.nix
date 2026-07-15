{
  lix,
  top,
  host,
  path,
  paths,
  ...
} @ args: let
  inherit (lix.attrsets) foldMerge mapAttrs optionalAttrs hasAttrByPath setAttrByPath;
  # inherit (lix.applications) resolveApps;
  inherit (lix.lists) findFirst head;
  inherit (lix.modules) mkIf mkMerge mkModules;
  inherit (lix.options) mkRegistryOptions mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr package str submodule;

  here = path;
  data = import (paths.store.api + "/${(head path)}");

  mkMod = {
    config,
    osConfig ? config,
    options ? {},
    scope ? "core",
    pkgs,
    path ? here,
    defaults ? {},
  }: let
    args = mkModuleArgs {
      inherit
        config
        defaults
        host
        options
        osConfig
        path
        pkgs
        scope
        top
        ;
    };
    inherit (args) get set;
    inherit (get) prettyName name cfg cfgOr apiOr;
    inherit (set) opt bin;

    registry = let
      derived = {
        enable = apiOr "enable";
        protocol = apiOr "protocol";
        uwsm = apiOr "uwsm";
        session = apiOr "session";
        needsXwaylandSatellite = apiOr "needsXwaylandSatellite";
        frontend = apiOr "frontend";
        greeter = apiOr "greeter";
        package = apiOr "package";
        configType = apiOr "configType";
        applications = apiOr "applications";
        bindings = apiOr "bindings";
      };
      defaults' = {
        inherit (get) package;
        enable = false;
        protocol = null;
        greeter = null;
        uwsm = null;
        session = name;
        needsXwaylandSatellite = false;
        frontend = null;
        applications = {
          browser = null;
          editor = null;
          visual = null;
          launcher = null;
          terminal = null;
        };
        bindings = {
          modifier = "SUPER";
          swapCapsEscape = false;
        };
      };

      updated =
        mapAttrs
        (
          key: value: let
            derivedValue = derived.${key} or null;
          in
            if derivedValue != null
            then derivedValue
            else value
        )
        (foldMerge [defaults' data defaults]);
    in
      updated
      // {
        uwsm =
          if derived.uwsm != null
          then derived.uwsm
          else updated.protocol == "wayland" && updated.enable;
      };

    fields =
      (mkRegistryOptions registry)
      // {
        enable = set.enable {default = registry.enable;};

        package = mkOption {
          type = nullOr package;
          default = registry.package;
          description = "Package backing the ${prettyName} compositor component.";
        };

        protocol = mkOption {
          type = nullOr (enum ["x11" "wayland"]);
          default = registry.protocol;
          description = "Display protocol for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        session = mkOption {
          type = nullOr str;
          default = registry.session;
          description = "Session name exported by ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        greeter = mkOption {
          type = nullOr str;
          default = registry.greeter;
          description = "Greeter or display manager preferred for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        frontend = mkOption {
          type = nullOr str;
          default = registry.frontend;
          description = "Frontend layer paired with ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        needsXwaylandSatellite =
          mkEnableOption "xwayland-satellite support for ${prettyName}"
          // {default = registry.needsXwaylandSatellite;};

        # variables = mkOption {
        #   type = attrs;
        #   description = "Pre-resolved application commands and keyboard shortcuts ready for hotkeys.";
        #   default =
        #     {MOD = registry.bindings.modifier;}
        #     // mapAttrs (name: app: app.command) (mkAppVars cfg.applications);
        # };
      }
      # // (mkVarOptions {inherit (default) variables;})
      # // (mkBindOptions {inherit (default) bindings;})
      # // (mkAppOptions {inherit (default) applications;})
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable = mkEnableOption "${prettyName} UWSM support." // {default = registry.uwsm;};
              name = mkOption {
                type = str;
                description = "Human-readable name shown by UWSM.";
                default = prettyName;
              };
              description = mkOption {
                type = str;
                description = "Comment shown by UWSM.";
                default = "${prettyName} compositor managed by UWSM";
              };
              binary = mkOption {
                type = str;
                description = "Absolute path to the compositor binary.";
                default = (bin {}).path;
              };
            };
          };
        };
      };

    target = findFirst (candidate: hasAttrByPath candidate options) null [
      ["wayland" "windowManager" name]
      ["programs" name]
    ];
    hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
    initiated = args // {inherit fields cfgOr;};
    evaluated = {
      options = opt fields;
      config =
        if scope == "home"
        then
          optionalAttrs (target != null) (setAttrByPath target (
            optionalAttrs (hasSub "enable") {inherit (cfg) enable;}
            // optionalAttrs (hasSub "package") {inherit (cfg) package;}
          ))
        else
          mkMerge [
            (mkIf (cfg.enable or false) (
              optionalAttrs
              (hasSub "enable")
              (setAttrByPath (target ++ ["enable"]) cfg.enable)
            ))
            (mkIf (cfg.enable or false) (
              optionalAttrs
              (hasSub "package")
              (setAttrByPath (target ++ ["package"]) cfg.package)
            ))
            (mkIf ((cfg.enable or false)
              && cfg.protocol == "wayland"
              && (cfg.uwsm.enable or false)) {
              programs.uwsm = {
                enable = true;
                waylandCompositors.${name} = {
                  prettyName = cfg.uwsm.name;
                  comment = cfg.uwsm.description;
                  binPath = cfg.uwsm.binary;
                };
              };
            })
          ];
    };
  in
    initiated // {inherit initiated evaluated;};

  inner = mkModules (args
    // {
      inherit data;
      base = ./.;
      declareRegistry = true;
      childPath = path;
      extraArgs = {
        mkArgs = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
          osConfig ? {},
          defaults ? {},
        }:
          mkMod {inherit config defaults options osConfig path pkgs scope;};
      };
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
