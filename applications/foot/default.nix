{
  imports = [
    ./core.nix
  ];

  home-manager = {
    sharedModules = [
      ./home.nix
    ];
  };
}
