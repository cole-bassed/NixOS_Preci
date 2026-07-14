{
  lix,
  top,
  host,
  path,
  ...
} @ args: let
  inherit (lix.attrsets) hasAttrByPath mapAttrs optionalAttrs recursiveUpdate setAttrByPath;
  inherit (lix.lists) findFirst;
  inherit (lix.modules) mkIf mkMerge mkModules;
  inherit (lix.options) mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) attrs enum listOf nullOr package str submodule;

  here = path;

  # Standard application choices defined exactly once
  registry = {
    browser = [
      {
        name = "zen-browser";
        description = "Zen Browser";
        command = "zen-twilight";
      }
      {
        name = "chromium";
        description = "Chromium";
        command = "chromium";
      }
      {
        name = "firefox";
        description = "Firefox";
        command = "firefox";
      }
    ];
    editor = {
      tty = [
        {
          name = "helix";
          description = "Helix Editor";
          command = "hx";
        }
        {
          name = "neovim";
          description = "NeoVim";
          command = "nvim";
        }
        {
          name = "nano";
          description = "GNU Nano";
          command = "nano";
        }
      ];
      gui = [
        {
          name = "vscode";
          description = "Visual Studio Code";
          command = "code";
        }
        {
          name = "zed";
          description = "Zed Editor";
          command = "zeditor";
        }
        {
          name = "antigravity";
          description = "Antigravity IDE";
          command = "antigravity";
        }
      ];
    };
    launcher = [
      {
        name = "vicinae";
        description = "Vicinae Launcher";
        command = "vicinae open";
      }
      {
        name = "fuzzel";
        description = "Fuzzel Launcher";
        command = "fuzzel";
      }
    ];
    terminal = [
      {
        name = "foot";
        description = "Foot Terminal";
        command = "foot";
      }
      {
        name = "ghostty";
        description = "Ghostty Terminal";
        command = "ghostty";
      }
      {
        name = "kitty";
        description = "Kitty Terminal";
        command = "kitty";
      }
    ];
    keyboard = {
      modifier = "SUPER";
    };
  };

  # Unified schema for prioritized applications
  appType = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Package name or lookup identifier.";
      };
      description = mkOption {
        type = str;
        description = "Human-readable descriptive label.";
      };
      command = mkOption {
        type = str;
        description = "The executable/binary command used to trigger it.";
      };
    };
  };

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
        scope
        top
        ;
    };
    inherit (args) get set;
    inherit (get) prettyName name cfg cfgOr apiOr;
    inherit (set) opt bin;

    # Smart cascading command resolver that reads fallbacks directly from the registry
    getAppCmd = list: baseRegistry: index: let
      len =
        if list == null || !builtins.isList list
        then 0
        else builtins.length list;
      regLen = builtins.length baseRegistry;
      resolve = idx:
        if len > idx
        then (builtins.elemAt list idx).command
        else if idx > 0
        then resolve (idx - 1) # Cascade downwards to the user's next best option
        else if regLen > 0
        then (builtins.elemAt baseRegistry 0).command # Absolute emergency registry floor
        else "";
    in
      resolve index;

    # Meta-helper to dynamically map standard tier structures without repetition
    resolveTiers = prefix: list: baseRegistry: {
      "${prefix}" = getAppCmd list baseRegistry 0;
      "${prefix}Alt" = getAppCmd list baseRegistry 1;
      "${prefix}Tertiary" = getAppCmd list baseRegistry 2;
    };

    default = let
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
        browser = apiOr "browser";
        editor = apiOr "editor";
        launcher = apiOr "launcher";
        terminal = apiOr "terminal";
        keyboard = apiOr "keyboard";
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
        (
          recursiveUpdate
          (recursiveUpdate defaults' registry)
          defaults
        );
    in
      updated
      // {
        uwsm =
          if derived.uwsm != null
          then derived.uwsm
          else updated.protocol == "wayland" && updated.enable;
      };

    fields =
      {
        enable = set.enable {default = default.enable;};

        package = mkOption {
          type = nullOr package;
          default = default.package;
          description = "Package backing the ${prettyName} compositor component.";
        };

        protocol = mkOption {
          type = nullOr (enum ["x11" "wayland"]);
          default = default.protocol;
          description = "Display protocol for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        session = mkOption {
          type = nullOr str;
          default = default.session;
          description = "Session name exported by ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        greeter = mkOption {
          type = nullOr str;
          default = default.greeter;
          description = "Greeter or display manager preferred for ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        frontend = mkOption {
          type = nullOr str;
          default = default.frontend;
          description = "Frontend layer paired with ${prettyName}. Defaults to the backend registry or host/user override.";
        };

        needsXwaylandSatellite =
          mkEnableOption "xwayland-satellite support for ${prettyName}"
          // {default = default.needsXwaylandSatellite;};

        browser = mkOption {
          type = nullOr (listOf appType);
          default = default.browser;
          description = "Ordered list of browsers from the registry.";
        };

        editor = mkOption {
          type = nullOr (submodule {
            options = {
              tty = mkOption {
                type = listOf appType;
                default = [];
                description = "Ordered list of terminal-based editors.";
              };
              gui = mkOption {
                type = listOf appType;
                default = [];
                description = "Ordered list of graphical editors.";
              };
            };
          });
          default = default.editor;
          description = "Ordered editor configurations categorized by interface from the registry.";
        };

        launcher = mkOption {
          type = nullOr (listOf appType);
          default = default.launcher;
          description = "Ordered list of application launchers from the registry.";
        };

        terminal = mkOption {
          type = nullOr (listOf appType);
          default = default.terminal;
          description = "Ordered list of terminal emulators from the registry.";
        };

        keyboard = mkOption {
          type = nullOr attrs;
          default = default.keyboard;
          description = "Keyboard config from the registry (modifier, etc.).";
        };

        # Pre-resolved environment variables completely decoupled from repetitive hardcoded strings!
        vars = mkOption {
          type = attrs;
          description = "Pre-resolved application commands and keyboard shortcuts ready for hotkeys.";
          default =
            {
              mod = cfg.keyboard.modifier or "SUPER";
            }
            // (resolveTiers "browser" cfg.browser registry.browser)
            // (resolveTiers "editor" (cfg.editor.tty or null) registry.editor.tty)
            // (resolveTiers "visual" (cfg.editor.gui or null) registry.editor.gui)
            // (resolveTiers "launcher" cfg.launcher registry.launcher)
            // (resolveTiers "terminal" cfg.terminal registry.terminal);
        };
      }
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable = mkEnableOption "${prettyName} UWSM support." // {default = default.uwsm;};
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
