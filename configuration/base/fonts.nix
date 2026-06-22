{
  lib,
  lix,
  top,
  dom,
  mod,
  host,
  userName ? null,
  ...
}: let
  inherit (lib.attrsets) attrValues isAttrs filterAttrs hasAttr getAttr;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists) foldl' optionals unique;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrsOf anything bool;

  getAttrPathOr = path: fallback: value: let
    result =
      foldl'
      (
        current: name:
          if (current == null) || !(isAttrs current) || !(hasAttr name current)
          then null
          else getAttr name current
      )
      value
      path;
  in
    if result == null
    then fallback
    else result;

  userValues =
    if host.users ? values
    then host.users.values
    else {};

  primaryUser = host.users.primary.value or null;

  selectedUser =
    if userName != null && hasAttr userName userValues
    then getAttr userName userValues
    else primaryUser;

  getUserName = user:
    if user != null && isAttrs user && user ? name
    then user.name
    else null;

  defaultFamilies = {
    emoji = "Noto Color Emoji";
    monospace = "Maple Mono NF";
    sans = "Monaspace Radon Frozen";
    serif = "Noto Serif";
    material = "Material Symbols Sharp";
    clock = "Rubik";
  };

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    getPkg = path: getAttrPathOr path null pkgs;

    packageMap = filterAttrs (_: value: value != null) {
      emoji = getPkg ["noto-fonts-color-emoji"];
      monospace = getPkg ["maple-mono" "NF"];
      sans = getPkg ["monaspace"];
      serif = getPkg ["noto-fonts"];
      material = getPkg ["material-symbols"];
      clock = getPkg ["rubik"];
    };

    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;

    userFamilies = getAttrPathOr ["style" "fonts"] {} selectedUser;
    hostFamilies = getAttrPathOr ["style" "fonts"] {} host;

    families = defaultFamilies // userFamilies // hostFamilies;

    mkPackageList = {
      packagesEnable,
      systemEnable ? false,
      homeEnable ? false,
      consoleEnable ? false,
      kmsconEnable ? false,
    }:
      unique (
        optionals (packagesEnable && systemEnable && scope == "core") (attrValues packageMap)
        ++ optionals (packagesEnable && homeEnable && scope == "home") (attrValues packageMap)
        ++ optionals (consoleEnable && scope == "core") [pkgs.terminus_font]
        ++ optionals (kmsconEnable && scope == "core" && packageMap ? monospace) [packageMap.monospace]
      );

    data = {
      inherit families packageMap;
      source = {
        primary = getUserName primaryUser;
        selected = getUserName selectedUser;
      };
      console = {
        package = pkgs.terminus_font;
        font = "ter-v32n";
        kernel = "TER16x32";
      };
      kmscon = {
        font = families.monospace;
        package = packageMap.monospace or null;
        fontSize = 32;
        term = "xterm-256color";
      };
    };
  in {
    options =
      (opt {
        enable = mkEnableMod.true;
        console.enable = mkOption {
          type = bool;
          default = true;
          description = "Enable the console font wiring exported by the base fonts module.";
        };
        kmscon.enable = mkOption {
          type = bool;
          default = true;
          description = "Enable kmscon using the resolved monospace family.";
        };
        fontconfig.enable = mkOption {
          type = bool;
          default = true;
          description = "Enable fontconfig defaults from the resolved semantic font families.";
        };
        packages = {
          enable = mkOption {
            type = bool;
            default = true;
            description = "Install the resolved font packages.";
          };
          system = mkOption {
            type = bool;
            default = true;
            description = "Install resolved font packages system-wide in the core scope.";
          };
          home = mkOption {
            type = bool;
            default = true;
            description = "Install resolved font packages in Home Manager profiles.";
          };
        };
      })
      // {
        ${top}.fonts = mkOption {
          type = attrsOf anything;
          default = {};
          description = "Resolved semantic font data: selected families, package mapping, console settings, and kmscon settings.";
        };
      };

    config = mkIf enable (mkMerge [
      {
        ${top}.fonts = data;
      }
      (mkIf (scope == "core" && (cfg.packages.enable || cfg.fontconfig.enable)) {
        fonts =
          (mkIf (cfg.packages.enable && cfg.packages.system) {
            packages = mkPackageList {
              packagesEnable = cfg.packages.enable;
              systemEnable = cfg.packages.system;
            };
          })
          // (mkIf cfg.fontconfig.enable {fontconfig.enable = true;});
      })
      (mkIf (scope == "core" && cfg.console.enable) {
        boot.kernelParams = ["fbcon=font:${data.console.kernel}"];
        console = {
          packages = [data.console.package];
          font = data.console.font;
        };
      })
      (mkIf (scope == "core" && cfg.kmscon.enable) {
        services.kmscon = {
          enable = true;
          hwRender = true;
          fonts = optionals (data.kmscon.package != null) [
            {
              name = data.kmscon.font;
              package = data.kmscon.package;
            }
          ];
          extraConfig = "font-size=${toString data.kmscon.fontSize}";
          extraOptions = "--term ${data.kmscon.term}";
        };
      })
      (mkIf (scope == "home" && cfg.packages.enable && cfg.packages.home) {
        home.packages = mkPackageList {
          packagesEnable = cfg.packages.enable;
          homeEnable = cfg.packages.home;
        };
      })
      (mkIf (scope == "home" && cfg.fontconfig.enable) {
        fonts.fontconfig = {
          enable = true;
          defaultFonts = {
            emoji = [families.emoji];
            monospace = [families.monospace];
            sansSerif = [families.sans];
            serif = [families.serif];
          };
        };
      })
    ]);
  };
in {
  core = mk "core";
  home = mk "home";
}
