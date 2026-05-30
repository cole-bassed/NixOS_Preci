{inputs, ...}: {
  home-manager = {
    sharedModules = [
      inputs.noctalia.homeModules.default
      ./home.nix
    ];
  };
}
