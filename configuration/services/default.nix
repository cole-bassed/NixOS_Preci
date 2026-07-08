{
  lix,
  host,
  ...
} @ args: let
  inherit (lix.ingestion) importModules;
  inherit (lix.attrsets) normalize;

  stagedServices = normalize (host.services or {});

  inner = importModules (args
    // {
      base = ./.;
      extraArgs.stagedServices = stagedServices;
      recurse = true;
    });

  hermes = import ./ai/hermes (args // {inherit stagedServices;});
  ollama = import ./ai/ollama (args // {inherit stagedServices;});
  openclaw = import ./ai/openclaw (args // {inherit stagedServices;});
  codex = import ./ai/codex (args // {inherit stagedServices;});
  claude = import ./ai/claude (args // {inherit stagedServices;});
in {
  core.imports =
    (inner.imports or [])
    ++ [
      hermes.core
      ollama.core
      openclaw.core
      codex.core
      claude.core
    ];

  home.imports =
    (inner.home-manager.sharedModules or [])
    ++ [
      hermes.home
      ollama.home
      openclaw.home
      codex.home
      claude.home
    ];
}
