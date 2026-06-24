{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.niri) nixosModules overlays;
in {
  imports = [nixosModules.niri];
  nixpkgs.overlays = [overlays.niri];

  programs = {
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };

    uwsm.waylandCompositors.niri = {
      prettyName = "Niri";
      comment = "Niri compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/niri-session";
    };
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite-unstable
  ];
}
