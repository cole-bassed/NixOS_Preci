{
  lix,
  api,
  top,
  path,
  ...
}: let
  inherit (lix.lists) last;
  inherit (lix.modules) mkDefault mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) bool package;
  inherit (lix) mkEnable;
  inherit (lix.options) mkModuleArgs mkApplicationOptions;

  rawName = last path;
  name = api.applications.aliases.${rawName} or rawName;
in {
  core = [];

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mkModuleArgs {inherit config top path scope;}) get set;
    inherit (get) cfg;
    inherit (set) opt;

    launch = "${cfg.package}/bin/vicinae open"; # TODO: this should be defined in the data layer. All apps mshould define things like command and so forth. something we started to do in data/interface/default.nix but needs to be added to each appentry's declaration file
  in {
    options = opt (
      (mkApplicationOptions {
        inherit name get scope pkgs;
      })
      // {
        fallbackPackage = mkOption {
          type = package;
          default = pkgs.fuzzel; # TODO: vicinae works on both protocols but fuzzel doesnt, so this has to be protocol dependent and we can use fuzzel vs rofi
          description = "Fallback launcher package used when Vicinae cannot open.";
        };

        systemd.enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to start the Vicinae daemon through Home Manager's user service.";
        };

        onHyprland = (mkEnable {name = "Vicinae on Hyprland";}).true;
        onNiri = (mkEnable {name = "Vicinae on Niri";}).true;
      }
    );

    config = mkIf cfg.enable {
      programs.vicinae = {
        enable = mkDefault true;
        package = mkDefault cfg.package;
        systemd.enable = mkDefault cfg.systemd.enable;
      };

      home.packages = [cfg.fallbackPackage];

      wayland.windowManager.hyprland.settings.bind = mkIf cfg.onHyprland [
        "SUPER, Z, exec, ${launch}"
      ];

      programs.niri.settings.binds = mkIf cfg.onNiri {
        "Mod+Z".action.spawn = [launch];
      };
    };
  };
}
