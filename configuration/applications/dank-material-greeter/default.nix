{
  lix,
  top,
  path,
  api,
  ...
}: let
  inherit (lix.attrsets) asAttrsIf filterAttrs;
  inherit (lix.lists) head;
  inherit (lix.modules) mkModuleArgs mkProgramToggle;
in
  (mkProgramToggle {inherit top path;})
  // {
    core = {
      config,
      pkgs,
      options,
      ...
    }: let
      mod = mkModuleArgs {inherit config top path pkgs options;} // {scope = "core";};
      inherit (mod) opt app cfg name; # `name` is the canonical registry name for
      # *this* module (e.g. "dms-greeter"), resolved via alias lookup --
      # never hardcoded.

      # Every backend (category = "backend") that declares THIS greeter
      # as its own registry `greeter`, filtered to those actually enabled
      # on this host/user.
      backends = api.interface.registry or {};
      candidateBackends =
        filterAttrs
        (backendName: entry:
          (entry.greeter or null)
          == name
          && (config.${top}.applications.${backendName}.enable or false))
        backends;

      # Prefer whichever candidate is the host/user's resolved primary
      # session (config.${top}.interface.session, from interface.environments
      # ordering); otherwise fall back to any enabled candidate.
      primarySession = config.${top}.interface.session or null;
      compositorName =
        if primarySession != null && candidateBackends ? ${primarySession}
        then primarySession
        else if candidateBackends != {}
        then head (lix.attrsets.namesOf candidateBackends)
        else null;
    in {
      options = opt app;
      config = {
        services.displayManager.${name} =
          {
            enable = cfg.enable or false;
            package = cfg.package;
          }
          // asAttrsIf (compositorName != null) {
            compositor.name = compositorName;
          };
      };
    };

    home = {
      config,
      pkgs,
      options,
      ...
    }: let
      scope = "home";
      mod = mkModuleArgs {inherit config scope top path pkgs options;};
    in {
      options = with mod; opt app;
      config = {};
    };
  }
