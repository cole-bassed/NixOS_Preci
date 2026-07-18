{
  lix,
  host,
  ...
} @ args: let
  inherit (lix.api) interface applications;
  inherit (lix.attrsets) asAttrsIf attrByPath mapAttrs setAttrByPath;
  inherit (lix.options) mkOption;
  inherit (lix.modules) mkIf mkMerge mkModuleArgs;
  inherit (lix.types) isNotEmpty isString nullAny nullStr;
  inherit (lix.strings) toJSON;

  mkModule = scope: {
    config,
    options,
    pkgs,
    ...
  }: let
    mod =
      mkModuleArgs (args
        // {inherit config options pkgs scope;});
    inherit (mod) get set;
    inherit (get) user;

    primary = interface.primaryOf {inherit user host;};
    secondary = interface.secondaryOf {inherit user host;};
    tertiary = interface.tertiaryOf {inherit user host;};
    aliases = applications.aliases or {};
    registry = applications.registry or {};

    inflate = entry:
      if entry == null
      then null
      else let
        rawName =
          if isString entry
          then entry
          else entry.name or (throw "interface: cannot resolve application name from ${toJSON entry}"); # TODO: Use debug.withContext
        name = aliases.${rawName} or rawName;
        registryEntry = registry.${name} or (throw "interface: '${name}' (resolved from '${rawName}') not found in dots.applications.registry");

        liveConfig = attrByPath (get.paths.custom ++ ["applications" name]) {} config;
        merged = registryEntry // liveConfig // {inherit name;};
      in
        removeAttrs merged ["applications" "bindings" "variables"];

    nameOf = input:
      if isString input
      then input
      else input.name or null;

    mkDefaults = session:
      asAttrsIf (isNotEmpty session) {
        session = session.name or null;
        greeter = inflate (session.greeter or null);
        frontend = inflate (session.frontend or null);
        protocol = let
          name = session.protocol or null;
          packages = with pkgs;
            if name == "wayland"
            then [wl-clipboard]
            else if name == "x11"
            then [xclip xsel]
            else [];
        in
          if name == null
          then null
          else {inherit name packages;};
      };

    defaults = mapAttrs (_: mkDefaults) {
      inherit primary secondary tertiary;
    };
    pri = defaults.primary;

    mkAppEnable = name:
      get.paths.custom
      ++ ["applications" name "enable"];

    enableComponent = component: let
      name = nameOf component;
    in
      mkIf (name != null)
      (setAttrByPath (mkAppEnable name) true);

    enableSession = tier: let
      name = tier.session or (tier.name or null);
    in
      mkIf (tier != null && name != null) (mkMerge [
        (setAttrByPath (mkAppEnable name) true)
        (enableComponent (tier.frontend or null))
        (mkIf (scope == "core") (enableComponent (tier.greeter or null)))
        (mkIf ((tier.protocol or null) != null)
          (with tier.protocol; (
            if scope == "core"
            then {environment.systemPackages = packages;}
            else {home = {inherit packages;};}
          )))
      ]);
  in {
    options = set.opt {
      session = mkOption {
        type = nullStr;
        default = pri.session;
        description = "Name of the primary session, for display-manager configuration.";
      };
      frontend = mkOption {
        type = nullStr;
        default = nameOf pri.frontend;
        description = "Name of the resolved frontend application for the primary session, or null.";
      };
      greeter = mkOption {
        type = nullStr;
        default = nameOf pri.greeter;
        description = "Name of the resolved greeter application for the primary session, or null.";
      };
      protocol = mkOption {
        type = nullAny;
        default = pri.protocol;
        description = "Display protocol of the primary session, as { name; packages; }.";
      };

      primary = mkOption {
        type = nullAny;
        default = defaults.primary;
      };
      secondary = mkOption {
        type = nullAny;
        default = defaults.secondary;
      };
      tertiary = mkOption {
        type = nullAny;
        default = defaults.tertiary;
      };
    };

    config = mkMerge [
      (enableSession defaults.primary)
      (enableSession defaults.secondary)
      (enableSession defaults.tertiary)
    ];
  };
in {
  core.imports = [(mkModule "core")];
  home.imports = [(mkModule "home")];
}
