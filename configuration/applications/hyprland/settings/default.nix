{
  lix,
  cfg,
  ...
}: let
  inherit (lix.modules) mkMerge;
in {
  settings = mkMerge [
    (import ./core.nix {inherit cfg lix;})
    (import ./bindings.nix {inherit cfg lix;})
    # (mkIf cfg.enableRules (import ./rules {inherit apps keyboard lib;}))
  ];
}
