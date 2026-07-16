{
  protocol = "wayland";
  greeter = "gdm";
  frontend = "gnome";
  applications = {
    explorer = [
      {
        name = "nautilus";
        description = "Nautilus File Manager";
        command = "nautilus";
        bindings = {launch = "E";};
      }
    ];
    terminal = [
      {
        name = "ptyxis-terminal";
        description = "Ptyxis Terminal";
        command = "ptyxis-terminal";
        bindings = {launch = "T";};
      }
    ];
  };
}
