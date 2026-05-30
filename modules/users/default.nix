{
  inputs,
  alpha,
  top,
  ...
}: let
  inherit (alpha) name description;
in {
  imports = with inputs; [home-manager.nixosModules.home-manager];

  users.users = {
    ${name} = {
      inherit description;
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"];
    };
  };

  home-manager = {
    backupFileExtension = "BaC";
    extraSpecialArgs = {inherit inputs top;};
    # sharedModules = with inputs; [
    #   niri.homeModules.niri
    #   vicinae.homeManagerModules.default
    #   noctalia.homeModules.default
    #   nix-colors.homeManagerModules.default
    # ];
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  security.sudo = {
    execWheelOnly = true;
    extraRules = [
      {
        users = [name];
        commands = [
          {
            command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      }
    ];
  };
}
