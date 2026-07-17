{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) genAttrs recursiveUpdate;
  inherit (lix.options) mkEnableOption mkOption;
  inherit (lix.types) nullOr str submodule;

  mk = args: mkArgs ({inherit extraArgs path;} // args);
  extraArgs = {fallbackConfig = "config/niri/config.kdl";};

  mkActionOption = description: overrides:
    mkOption {
      type = submodule {
        options = {
          command = mkOption {
            type = nullOr str;
            default = overrides.command or null;
            description = "Shell command for the ${description} action.";
          };
          description = mkOption {
            type = str;
            default = overrides.description or description;
            description = "Human-readable label for the ${description} action.";
          };
        };
      };
      default = {};
      description = "Shared semantic Niri action for ${description}.";
    };

  mkOptions = overrides: {
    fallbackConfig = mkOption {
      type = str;
      default =
        if (overrides.fallbackConfig or null) != null
        then overrides.fallbackConfig
        else extraArgs.fallbackConfig;
      description = "Path to Niri fallback KDL configuration.";
    };

    semanticKeybinds =
      mkEnableOption "modular semantic keybind layer for Niri"
      // {default = true;};

    actions = {
      secondaryLauncher = mkActionOption "secondary launcher" {
        command = "fuzzel";
        description = "Open Fuzzel";
      };
      showKeybinds = mkActionOption "show keybinds/help" {
        command = "dots-common-keybinds";
        description = "Show common keybinds";
      };
      terminal = mkActionOption "terminal" {
        command = "foot";
        description = "Open terminal";
      };
      scratchpadTerminal = mkActionOption "scratchpad/quake terminal" {
        command = "foot --app-id dots-scratchpad";
        description = "Open scratchpad terminal";
      };
      primaryBrowser = mkActionOption "primary browser" {
        command = "zen";
        description = "Open primary browser";
      };
      secondaryBrowser = mkActionOption "secondary browser" {
        command = "chromium";
        description = "Open secondary browser";
      };
      visualTools = mkActionOption "visual tools" {
        command = "vicinae open || fuzzel";
        description = "Open visual tools";
      };
      fileManager = mkActionOption "file manager" {
        command = "xdg-open $HOME";
        description = "Open file manager";
      };
      editor = mkActionOption "editor" {
        command = "code";
        description = "Open editor";
      };
      fullscreen = mkActionOption "fullscreen" {description = "Toggle fullscreen";};
      logout = mkActionOption "logout/exit session" {description = "Exit compositor session";};
      closeWindow = mkActionOption "close window" {description = "Close focused window";};
      lock = mkActionOption "lock" {
        command = "loginctl lock-session";
        description = "Lock session";
      };
      screenshot = mkActionOption "screenshot" {
        command = ''grim -g "$(slurp)" - | wl-copy'';
        description = "Take a screenshot";
      };
    };
  };
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) apiOr set evaluated;
  in {
    options = recursiveUpdate evaluated.options (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
    inherit (evaluated) config;
  };

  home = {
    config,
    options,
    pkgs,
    osConfig,
    ...
  }: let
    scope = "home";
    mod = mk {inherit config options osConfig pkgs scope;};
    inherit (mod) apiOr set evaluated;
  in {
    imports = [./bindings.nix ./packages.nix];
    options = recursiveUpdate evaluated.options (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
    inherit (evaluated) config;
  };
}
