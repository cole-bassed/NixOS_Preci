{
  inputs,
  alpha,
  top,
  lix,
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
    extraSpecialArgs = {inherit inputs lix top;};
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
