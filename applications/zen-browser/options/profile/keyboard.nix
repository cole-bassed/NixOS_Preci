{
  lib,
  top,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs int listOf nullOr;

  dom = "applications";
  mod = "zen-browser";
in {
  options.${top}.${dom}.${mod}.profile = {
    keyboardShortcutsVersion = mkOption {
      type = nullOr int;
      default = 19;
      description = "Expected Zen keyboard shortcut schema version.";
    };

    keyboardShortcuts = mkOption {
      type = listOf attrs;
      default = [
        {
          id = "zen-compact-mode-toggle";
          key = "c";
          modifiers = {
            control = true;
            alt = true;
          };
        }
        {
          id = "zen-toggle-sidebar";
          key = "x";
          modifiers = {
            control = true;
            alt = true;
          };
        }
        {
          id = "key_quitApplication";
          disabled = true;
        }
        {
          id = "key_reload";
          key = "r";
          modifiers.control = true;
        }
        {
          id = "key_reload_skip_cache";
          key = "r";
          modifiers = {
            control = true;
            shift = true;
          };
        }
      ];
      description = "Declarative keyboard shortcut overrides for the configured profile.";
    };
  };
}
