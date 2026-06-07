{pkgs, ...}: {
  boot = {
    kernelParams = ["fbcon=font:TER16x32"];
  };

  console = {
    packages = [pkgs.terminus_font];
    font = "ter-v32n";
  };

  services = {
    kmscon = {
      hwRender = true;
      fonts = [
        {
          name = "Maple Mono NF";
          package = pkgs.maple-mono.NF;
        }
      ];
      extraConfig = "font-size=32";
      extraOptions = "--term xterm-256color";
    };
  };
}
