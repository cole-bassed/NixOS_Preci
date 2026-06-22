# configuration/base/system.nix
{
  lix,
  top,
  host,
  ...
}: let
  inherit (lix.modules) mkDefault;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;

  data = {
    name = host.name or "nixos";
    id = host.id or null;
    description = host.description or null;
    type = host.type or null;
    class = host.class or "nixos";
    platform = host.system or "x86_64-linux";
    stateVersion = host.stateVersion or "25.11";
  };

  mk = scope: {...}: {
    options.${top}.system = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Resolved host system metadata: hostname, id, description, form factor, OS class, platform, and state version.";
    };

    config =
      {${top}.system = data;}
      // (
        if scope == "core"
        then {
          networking.hostName = mkDefault data.name;
          system.stateVersion = mkDefault data.stateVersion;
          nixpkgs.hostPlatform = mkDefault data.platform;
        }
        else {}
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
