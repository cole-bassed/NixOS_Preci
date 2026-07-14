{
  lix,
  cfg,
  # host,
  # apps,
  # host,
  # lib,
  # lix,
  # keyboard,
  # keys,
  ...
}: let
  inherit (lix.modules) mkIf mkMerge;
in {
  settings = mkMerge [
    (import ./core.nix {inherit cfg;})
    # (import ./io.nix {inherit apps host lix lib keyboard;})
    # (mkIf cfg.enableRules (import ./rules {inherit apps keyboard lib;}))
  ];
}
