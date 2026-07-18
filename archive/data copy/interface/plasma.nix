{
  protocol = "wayland";
  greeter = "plasma-login-manager";
  frontend = "plasma";
  applications = {
    explorer = [
      {
        name = "dolphin";
        description = "Dolphin File Manager";
        command = "dolphin";
        bindings = {launch = "E";};
      }
    ];
    terminal = [
      {
        name = "konsole";
        description = "Konsole";
        command = "konsole";
        bindings = {launch = "T";};
      }
    ];
  };
}
