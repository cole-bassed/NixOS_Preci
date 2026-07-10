{
  lix,
  top,
  shared,
  ...
} @ args: let
  inherit (lix.ingestion) importModules;
  inherit (lix.lists) last;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything;

  registry = {
    claude = {
      provider = "anthropic";
      requiresContainer = false;
      homeCapable = true;
    };
    codex = {
      provider = "openai";
      requiresContainer = false;
      homeCapable = true;
    };
    ollama = {
      provider = "local";
      requiresContainer = false;
      homeCapable = false;
    };
    openclaw = {
      provider = "openclaw";
      requiresContainer = false;
      homeCapable = true;
    };
    hermes = {
      provider = "openai-codex";
      requiresContainer = true;
      homeCapable = false;
    };
  };

  mkChild = {
    path,
    extraOptions ? (_: {}),
    extraConfig ? (_: {}),
  }: let
    name = last path;
    entry = registry.${name} or {};
    staged = shared.ai.${name} or {};

    defaults = {
      enable = staged.enable or false;
      provider = staged.provider or (entry.provider or null);
    };

    mk = scope: {
      config,
      options ? {},
      pkgs ? {},
      ...
    }: let
      mod = mkModuleArgs {inherit config options top scope path;};
      opt = mod.set.options.module;
      cfg = mod.get.config.module;

      fields = {
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
    in {
      options = opt (fields // extraOptions {inherit scope cfg entry staged;});
      config = extraConfig {inherit scope cfg entry staged pkgs;};
    };
  in {
    core = mk "core";
    home = mk "home";
  };

  inner = importModules (args
    // {
      base = ./.;
      declareRegistry = true;
      extraArgs = {inherit shared registry mkChild;};
      excludes = [
        "claude"
        # "codex"
        "ollama"
        "openclaw"
      ];
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
