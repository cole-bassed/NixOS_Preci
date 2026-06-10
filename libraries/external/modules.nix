{
  bootstrap,
  defaults,
  inputs,
  ...
}: let
  inherit (bootstrap) attrsets config lists;
  inherit (config) collect;
  inherit (lists) asListIf isIn;
  inherit (attrsets) filter isAttrs;

  excludes = defaults.excludes.modules or [];

  raw =
    filter
    (input: _: !(isIn input excludes))
    inputs.classified.modules;

  classified = let
    mk = type: collect type raw;
  in {
    nixos = mk "nixos";
    darwin = mk "darwin";
    home = mk "home";
  };

  normalized = {
    home-manager = type: let
      key =
        if type == "nixos"
        then "nixosModules"
        else if type == "darwin"
        then "darwinModules"
        else null;
      input = inputs.normalized.home-manager;
    in
      asListIf
      (
        (key != null)
        && (isAttrs input)
        && input ? ${key}.home-manager
      )
      input.${key}.home-manager;
  };

  merged = classified // normalized;

  mkCore = type:
    if type == "nixos" || type == "darwin"
    then
      classified.${type}
      ++ normalized.home-manager type
      ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
    else throw "external.modules.mkCore: unknown type '${type}'";
in {inherit raw classified normalized excludes merged mkCore;}
