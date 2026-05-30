{
  imports = [
    ./craole/core
  ];

  home-manager = {
    users = {
      craole = import ./craole/home;
    };
  };
}
