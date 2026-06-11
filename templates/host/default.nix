{flake ? {}, ...}: let
  name = "NewHost";
in {
  inherit name;
  class = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  users.admin = {
    role = "administrator";
    primary = true;
  };
}
