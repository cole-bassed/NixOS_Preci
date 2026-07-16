{
  protocol = "wayland";
  greeter = "cosmic-greeter";
  frontend = "cosmic";
  applications.terminal = [
    {
      name = "cosmic-terminal";
      description = "COSMIC Terminal";
      command = "cosmic-term";
      bindings = {launch = "T";};
    }
  ];
}
