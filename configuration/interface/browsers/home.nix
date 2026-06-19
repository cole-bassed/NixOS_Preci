{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr package str;

  dom = "interface";
  mod = "browsers";

  cfg = config.${top}.${dom}.${mod};

  browserMimeTypes = [
    "text/html"
    "x-scheme-handler/about"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];

  defaultDesktop =
    if cfg.primary.desktop != null
    then cfg.primary.desktop
    else cfg.secondary.desktop;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "desktop browser defaults";

    primary.package = mkOption {
      type = nullOr package;
      default = null;
      description = ''
        Preferred Zen/Twilight browser package when the flake provides one.
        Null means no Zen/Twilight browser target is currently available.
      '';
    };

    primary.desktop = mkOption {
      type = nullOr str;
      default = null;
      description = "Desktop file name for the preferred primary browser.";
    };

    secondary.package = mkOption {
      type = package;
      default = pkgs.chromium;
      description = "Chromium-based fallback browser package.";
    };

    secondary.desktop = mkOption {
      type = str;
      default = "chromium-browser.desktop";
      description = "Desktop file name for the Chromium-based fallback browser.";
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      [cfg.secondary.package]
      ++ optional (cfg.primary.package != null) cfg.primary.package;

    xdg.mimeApps = {
      enable = mkDefault true;
      defaultApplications = genAttrs browserMimeTypes (_:
        mkDefault (
          [defaultDesktop]
          ++ optional (cfg.secondary.desktop != defaultDesktop) cfg.secondary.desktop
        ));
    };
  };
}
