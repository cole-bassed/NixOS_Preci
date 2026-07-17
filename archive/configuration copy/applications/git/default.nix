{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.modules) mkDefault mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) package;

  mk = args: mkArgs ({inherit path;} // args);
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    node = mk {inherit config pkgs;};
    inherit (node) get set pkgName;
    cfg = get.config.module;
    opt = set.options.module;
  in {
    options = opt {
      enable = set.enable {default = false;};
      package = mkOption {
        type = package;
        default = pkgs.${pkgName};
        description = "Package of '${get.name}' to install system-wide.";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [cfg.package];
    };
  };

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    node = mk {inherit config pkgs scope;};
    inherit (node) get set pkgName;
    cfg = get.config.module;
    opt = set.options.module;
  in {
    options = opt {
      enable = set.enable {default = false;};
      package = mkOption {
        type = package;
        default = pkgs.${pkgName};
        description = "Package of '${get.name}' to enable for the user.";
      };
    };
    config = mkIf cfg.enable {
      programs.git = {
        enable = mkDefault true;
        inherit (cfg) package;
        settings = {
          init.defaultBranch = mkDefault "main";
          pull.rebase = mkDefault true;
          rebase.autoStash = mkDefault true;
          push.autoSetupRemote = mkDefault true;
          core.editor = mkDefault "hx";
          merge.conflictStyle = mkDefault "zdiff3";
        };
      };
    };
  };
}
