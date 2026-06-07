{pkgs, ...}: {
  programs = {
    uwsm.enable = true;
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      wl-clipboard-rs
      wayland-utils
      libsecret
      cage
    ];
  };
}
