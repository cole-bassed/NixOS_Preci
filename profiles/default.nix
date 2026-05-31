{
  config,
  lix,
  lib,
  ...
} @ args: let
  inherit (lib.attrsets) attrValues mapAttrs filterAttrs;
  inherit (lib.lists) concatMap;
  inherit (lib.filesystem) readDir;
  inherit (lix) asList;

  entries = filterAttrs (n: v: v == "directory") (readDir ./.);

  importProfile = name:
    import (./. + "/${name}/default.nix") (args
      // {
        dom = "profiles";
        mod = name;
      });

  profiles = mapAttrs (name: _: importProfile name) entries;

  mkUser = name: profile: {
    imports =
      [
        {
          home.stateVersion = config.system.stateVersion;
          programs.home-manager.enable = true;
        }
      ]
      ++ (asList (profile.home or null));
  };
in {
  imports = concatMap (p: asList (p.core or null)) (attrValues profiles);
  home-manager.users = mapAttrs mkUser profiles;
}
