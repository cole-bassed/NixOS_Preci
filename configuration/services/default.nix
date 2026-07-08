{
  lix,
  top,
  host,
  config,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;

  raw = host.services or [];

  normalizeValue = value:
    if builtins.isBool value
    then {enable = value;}
    else if builtins.isAttrs value
    then ({enable = value.enable or true;} // value)
    else {
      enable = true;
      inherit value;
    };

  normalize = value:
    if builtins.isList value
    then
      builtins.listToAttrs (map (name: {
          inherit name;
          value = {enable = true;};
        })
        value)
    else if builtins.isAttrs value
    then builtins.mapAttrs (_: normalizeValue) value
    else {};

  data = normalize raw;

  mk = scope: _: {
    options.${top}.services = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Resolved service selections and per-service metadata sourced from the host/user API.";
    };

    config =
      {${top}.services = data;}
      // (
        if scope == "core"
        then {
          services.tailscale = mkIf (config.${top}.services.tailscale.enable or false) {
            enable = true;
            openFirewall = true;
          };
        }
        else {}
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
