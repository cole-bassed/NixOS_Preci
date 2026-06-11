# configuration/modules/base/system.nix
{
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  core = {
    system.stateVersion = mkDefault (host.stateVersion or "25.11");
  };
}
