{
  services = {
    keyd = {
      enable = true;
      keyboards.default = {
        # TODO: Replace this temporary global fallback with an RK71-specific
        # device id once it is known. The RK71 needs Caps Lock as Escape, but
        # the CIDOO keyboard already handles that in hardware.
        ids = [""];
        settings = {
          main = {
            capslock = "esc";
          };
        };
      };
    };
  };
}
