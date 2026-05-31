{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.twilight
    ./options/general.nix
    ./options/policies.nix
    ./options/profile/bookmarks.nix
    ./options/profile/containers.nix
    ./options/profile/keyboard.nix
    ./options/profile/pins.nix
    ./options/profile/search.nix
    ./options/profile/settings.nix
    ./options/profile/spaces.nix
    ./options/profile/style.nix
    ./program.nix
  ];
}
