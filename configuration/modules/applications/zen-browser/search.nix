{
  lib,
  pkgs,
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
      profile.search = mkOption {
        type = attrs;
        default = {
          force = true;
          default = "ddg";
          engines = {
            mynixos = {
              name = "My NixOS";
              urls = [
                {
                  template = "https://mynixos.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@nx"];
            };
            github = {
              name = "GitHub Search";
              urls = [{template = "https://github.com/search?q={searchTerms}";}];
              definedAliases = ["@gh"];
            };
          };
        };
        description = "Search engines and defaults for the configured profile.";
      };
    };
  };
}
