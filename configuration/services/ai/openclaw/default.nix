{
  lix,
  top,
  shared,
  path,
  registry,
  ...
}: let
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything;
  inherit (lix.lists) last;

  name = last path;
  defaults = let
    staged = shared.ai.${name} or {};
    entry = registry.${name} or {};
  in {
    enable = staged.enable or false;
    provider = staged.provider or (entry.provider or null);
  };

  mk = scope: {config, ...}: let
    mod = mkModuleArgs {inherit config top scope path;};
    opt = mod.set.options.module;
  in {
    options = opt {
      enable = mkEnable {
        inherit name scope;
        default = defaults.enable;
      };

      provider = mkOption {
        type = anything;
        default = defaults.provider;
        description = "AI provider backing ${name}.";
      };
    };

    config = {};
  };
in {
  core = mk "core";
  home = mk "home";
}
