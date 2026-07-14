{
  lix,
  top,
  host,
  path,
  # registry,
  # selection,
  ...
} @ args: let
  inherit (lix.attrsets) hasAttrByPath optionalAttrs setAttrByPath;
  inherit (lix.lists) findFirst;
  inherit (lix.modules) mkIf mkMerge mkModules;
  inherit (lix.options) mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) enum nullOr package str submodule;

  here = path;

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
      lib = lix;
      inherit
        config
        defaults
        host
        options
        osConfig
        path
        pkgs
        # registry
        scope
        top
        ;
    };
    inherit (args) get set;
    inherit (get) prettyName name cfg cfgOr apiOr;
    inherit (set) opt bin;

    protocol = apiOr "protocol";
    isWayland = protocol == "wayland";
    # enabled = get.enabled {inherit selection;};
    enabled = get.enabled {};
    fields =
      {
        enable = set.enable {default = enabled;};
        package = mkOption {
          type = nullOr package;
          default = get.package;
          description = "Package backing the ${prettyName} compositor component.";
        };
        protocol = mkOption {
          type = nullOr (enum ["x11" "wayland"]);
          default = protocol;
          description = "Display protocol for ${prettyName}. Defaults to the backend registry or host/user override.";
        };
        session = mkOption {
          type = nullOr str;
          default = let
            value = apiOr "session";
          in
            if value != null
            then value
            else name;
          description = "Session name exported by ${prettyName}. Defaults to the backend registry or host/user override.";
        };
        greeter = mkOption {
          type = nullOr str;
          default = apiOr "greeter";
          description = "Greeter or display manager preferred for ${prettyName}. Defaults to the backend registry or host/user override.";
        };
        frontend = mkOption {
          type = nullOr str;
          default = apiOr "frontend";
          description = "Frontend layer paired with ${prettyName}. Defaults to the backend registry or host/user override.";
        };
        needsXwaylandSatellite =
          mkEnableOption "xwayland-satellite support for ${prettyName}"
          // {
            default = let
              value = apiOr "needsXwaylandSatellite";
            in
              if value != null
              then value
              else false;
          };
      }
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable =
                mkEnableOption "${prettyName} UWSM support."
                // {
                  default = let
                    choice = apiOr "uwsm";
                  in
                    if choice != null
                    then choice
                    else isWayland && enabled;
                };
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
            optionalAttrs (hasSub "enable") {enable = cfg.enable;}
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
                waylandCompositors.${name} = with cfg.uwsm; {
                  prettyName = name;
                  comment = description;
                  binPath = binary;
                };
              };
            })
          ];
    };
  in
    initiated // {inherit initiated evaluated;};

  inner = mkModules (args
    // {
      base = ./.;
      declareRegistry = false;
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
