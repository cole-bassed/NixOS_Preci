{
  lix,
  host,
  ...
} @ args: let
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

  stagedServices = normalize raw;

  inner = lix.importModules (args
    // {
      base = ./.;
      recurse = true;
      extraArgs =
        (args.extraArgs or {})
        // {
          inherit stagedServices;
        };
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
