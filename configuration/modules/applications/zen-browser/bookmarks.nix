{
  lib,
  mkArgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) opt;
  in {
    options = opt {
      profile.bookmarks = mkOption {
        type = attrs;
        default = {
          force = true;
          settings = [
            {
              name = "Nix Sites";
              toolbar = true;
              bookmarks = [
                {
                  name = "homepage";
                  url = "https://nixos.org/";
                }
                {
                  name = "wiki";
                  tags = ["wiki" "nix"];
                  url = "https://wiki.nixos.org/";
                }
                {
                  name = "packages";
                  url = "https://search.nixos.org/packages";
                }
              ];
            }
            {
              name = "Development";
              bookmarks = [
                {
                  name = "GitHub";
                  url = "https://github.com";
                }
              ];
            }
          ];
        };
        description = "Declarative bookmarks for the configured profile.";
      };
    };
  };
}
