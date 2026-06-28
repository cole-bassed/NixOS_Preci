{
  lix,
  top,
  paths,
  ...
}: let
  inherit (lix.attrsets) filterAttrs mapAttrs mapAttrs';
  inherit (lix.environment) mkVariables mkCdAliases;
  inherit (lix.lists) elem;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;

  paths' = {
    local = paths.local or {};
    store = paths.store or {};
  };

  keys = {
    core = [
      "api"
      "configuration"
      "dbg"
      "documentation"
      "libraries"
      "secrets"
      "shells"
      "src"
      "templates"
      "utilities"
    ];
    home = [
      "documents"
      "downloads"
      "music"
      "pictures"
      "projects"
      "videos"
    ];
  };

  # Filters any local-style path map down to one of the key groups above.
  pick = scope: local: filterAttrs (name: _: elem name keys.${scope}) local;

  mkGroup = attrs: {
    variables = mkVariables {
      inherit attrs;
      prefix = top;
    };
    aliases = mkCdAliases attrs;
  };

  mk = scope: {config, ...}: let
    cfg = config.${top}.paths or {};
    group = mkGroup (
      if scope == "core"
      then let
        local = pick "core" paths'.local;
        store =
          mapAttrs' (name: value: {
            name = "${name}_store";
            inherit value;
          })
          (pick "core" paths'.store);
      in
        local // store
      else pick "home" (cfg.local or paths'.local)
    );
  in {
    options.${top}.paths = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Staged path data for dots: raw local/store maps, core.{variables,aliases}, and a per-user home.<user>.{variables,aliases} breakdown -- the single source injected into environment/home options.";
    };

    config =
      {
        ${top}.paths =
          {inherit (paths') local store;}
          // (
            if scope == "core"
            then {
              core = group;
              home = mapAttrs (
                _: userCfg: userCfg.${top}.paths.home or {}
              ) (config.home-manager.users or {});
            }
            else {home = group;}
          );
      }
      // (
        if scope == "core"
        then {
          environment = {
            inherit (group) variables;
            shellAliases = group.aliases;
          };
        }
        else {
          home = {
            sessionVariables = group.variables;
            shellAliases = group.aliases;
          };
        }
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
