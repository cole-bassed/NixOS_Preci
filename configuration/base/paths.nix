{
  lix,
  top,
  dom,
  mod,
  paths,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.lists) elem;
  inherit (lix.options) mkModuleArgs;
  inherit (lix.attrsets) filterAttrs;
  inherit (lix.environment) mkVariables mkCdAliases;

  # Paths describing the dotfiles project itself -- host-level, the same
  # for every user on the box. Per-user media folders (documents,
  # downloads, pictures, projects, etc.) are deliberately excluded here;
  # those belong in home-manager, one layer up.
  projectKeys = [
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

  projectPaths = filterAttrs (name: _: elem name projectKeys) (paths.local or {});

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
    };

    config = mkIf enable (
      if scope == "core"
      then {
        environment.variables = mkVariables {
          prefix = "dots";
          attrs = projectPaths;
        };
        environment.shellAliases = mkCdAliases projectPaths;
      }
      else {}
    );
  };
in {
  core = mk "core";
}
