{
  api,
  debug,
  attrsets,
  lists,
  types,
  flakes,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit per classification builder current;
      forEach = per;
      getBuilder = builder;
      getClassification = classification;
    };
    global = {
      forEachSystem = per;
      currentSystem = current;
      systemOf = current;
    };
  };

  inherit (attrsets) attrValues genAttrs;
  inherit (debug) withContext;
  inherit (lists) elem unique;
  inherit (types) isFunction;
  inherit (api) hosts;
  inherit (strings) concat;

  classification = class:
    assert withContext {
      name = "config.systemType";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing system type from class";
    };
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";

  builder = class: let
    opts = ["nixos" "darwin"];
  in
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class opts;
      message = ''expected one of [${concat {
          delim = ", ";
          parts = opts;
        }}], got ${class}'';
      context = "parsing system builder from class";
    };
    with flakes.libraries.default;
      if class == "nixos"
      then nixpkgs.nixosSystem or {}
      else nix-darwin.darwinSystem or {};

  supported = {extra ? []}:
    unique (
      extra
      ++ map (host: host.system or (host.platform or hosts.default.system))
      (attrValues hosts)
    );

  per = arg: let
    opts =
      if isFunction arg
      then {fn = arg;}
      else arg;
    packages = opts.packages or flakes.packages.default;
    extra = opts.extra or [];
  in
    genAttrs
    (supported {inherit extra;})
    (system: opts.fn packages.${system});
  # TODO: add kind (get via parsing input or pkgs.stdenv.hostPlatform) and getOrDefault (via kind or builtins.currentSystem or most common system from api hosts)

  current = pkgs: pkgs.stdenv.hostPlatform.system or builtins.currentSystem;
in
  exports
