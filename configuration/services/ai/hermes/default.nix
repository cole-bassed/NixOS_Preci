{
  lix,
  top,
  shared,
  path,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs recursiveUpdate;
  inherit (lix.lists) last optional;
  inherit (lix.modules) mkDefault mkIf;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) attrs bool int listOf nullOr str;

  name = last path;
  staged = shared.ai.${name} or {};

  mkDirs = state: {
    inherit state;
    home = "${state}/.hermes";
    workspace = "${state}/workspace";
    docs = ./instructions;
  };

  defaults = {
    enable = staged.enable or false;
    directories = mkDirs (staged.stateDirectory or "/var/lib/hermes");
    addToSystemPackages = staged.addToSystemPackages or true;
    extraDependencyGroups = staged.extraDependencyGroups or ["messaging" "edge-tts"];
    extraArgs = staged.extraArgs or [];
    restart = staged.restart or "always";
    restartSec = staged.restartSec or 5;

    container = recursiveUpdate {enable = false;} (staged.container or {});

    envSecret = recursiveUpdate {
      enable = staged.enable or false;
      name = "services/ai/hermes/env";
      path = null;
    } (staged.envSecret or {});

    settings = recursiveUpdate {
      model = {
        provider = "openai-codex";
        default = "gpt-5.5";
      };
      toolsets = ["all"];
      max_turns = 100;
      terminal = {
        backend = "local";
        timeout = 180;
        cwd = defaults.directories.workspace;
      };
      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "gpt-5.4-mini";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "kawaii";
      };
      agent = {
        max_turns = 60;
        verbose = false;
      };
    } (staged.settings or {});

    instructions =
      recursiveUpdate
      {"USER" = ./instructions + "/USER.md";}
      (staged.instructions or {});
  };

  mk = scope: {
    config,
    options,
    pkgs,
    ...
  }: let
    mod = mkModuleArgs {
      inherit config options top scope path;
    };
    opt = mod.set.options.module;
    cfg = mod.get.config.module;
    inherit (pkgs) writeShellApplication;
  in {
    options = opt {
      enable = mkEnable {
        inherit name scope;
        default = defaults.enable;
      };

      stateDirectory = mkOption {
        type = str;
        default = defaults.directories.state;
        description = "Persistent runtime root for the system Hermes instance. Rebuild-safe mutable state lives here rather than in the Nix store.";
      };

      container.enable = mkOption {
        type = bool;
        default = defaults.container.enable;
        description = "Whether Hermes Agent should run inside its upstream container integration.";
      };

      envSecret = {
        enable = mkEnable {
          name = "hermes env secret";
          inherit scope;
          default = defaults.envSecret.enable;
        };
        name = mkOption {
          type = str;
          default = defaults.envSecret.name;
          description = "Logical sops secret name that stores the Hermes environment file for this host.";
        };
        path = mkOption {
          type = nullOr str;
          default = defaults.envSecret.path;
          description = "Resolved filesystem path for the decrypted Hermes environment file, materialized by the secrets layer.";
        };
      };

      extraDependencyGroups = mkOption {
        type = listOf str;
        default = defaults.extraDependencyGroups;
        description = "Hermes Agent optional dependency groups to install.";
      };

      settings = mkOption {
        type = attrs;
        default = defaults.settings;
        description = "Hermes Agent config.yaml settings rendered by the NixOS module.";
      };

      instructions = mkOption {
        type = attrs;
        default = defaults.instructions;
        description = "Documents linked into Hermes Agent context.";
      };

      addToSystemPackages = mkOption {
        type = bool;
        default = defaults.addToSystemPackages;
        description = "Whether the upstream Hermes package should be added to system packages.";
      };

      extraArgs = mkOption {
        type = listOf str;
        default = defaults.extraArgs;
        description = "Extra command-line arguments passed to the Hermes Agent service.";
      };

      restart = mkOption {
        type = str;
        default = defaults.restart;
        description = "Systemd Restart policy for the Hermes Agent service.";
      };

      restartSec = mkOption {
        type = int;
        default = defaults.restartSec;
        description = "Seconds to wait before restarting the Hermes Agent service.";
      };
    };

    config = optionalAttrs (scope == "core") (mkIf cfg.enable (let
      directories = mkDirs cfg.stateDirectory;

      settings = recursiveUpdate cfg.settings {
        terminal.cwd = directories.workspace;
      };

      envSecretPath =
        if cfg.envSecret.path != null
        then cfg.envSecret.path
        else (config.sops.secrets.${cfg.envSecret.name} or {}).path or null;

      applications = {
        gateway = writeShellApplication {
          name = "hermes-gateway";
          text = ''
            exec /run/wrappers/bin/sudo -u hermes \
              env HERMES_HOME="${directories.home}" HOME="${directories.state}" \
              /run/current-system/sw/bin/hermes "$@"
          '';
        };

        dots = writeShellApplication {
          name = "dots-hermes";
          text = ''
            unset HERMES_HOME
            cd "''${DOTS:-${config.${top}.paths.local.src or directories.workspace}}"
            exec hermes "$@"
          '';
        };
      };
    in {
      assertions = [
        {
          assertion = !cfg.envSecret.enable || envSecretPath != null;
          message = "${top}.services.ai.hermes.envSecret.enable requires the secrets layer to materialize ${cfg.envSecret.name}.";
        }
      ];

      environment = {
        systemPackages = [applications.gateway applications.dots];
      };

      services = {
        hermes-agent = {
          enable = mkDefault true;
          container.enable = mkDefault cfg.container.enable;
          extraDependencyGroups = mkDefault cfg.extraDependencyGroups;
          settings = mkDefault settings;
          environmentFiles = optional cfg.envSecret.enable envSecretPath;
          documents = mkDefault cfg.instructions;
          addToSystemPackages = mkDefault cfg.addToSystemPackages;
          extraArgs = mkDefault cfg.extraArgs;
          restart = mkDefault cfg.restart;
          restartSec = mkDefault cfg.restartSec;
        };
      };

      systemd = {
        services.hermes-agent.serviceConfig =
          {
            TimeoutStopSec = 240;
            UnsetEnvironment = ["MESSAGING_CWD"];
          }
          // optionalAttrs cfg.envSecret.enable {
            EnvironmentFile = envSecretPath;
          };

        tmpfiles.rules =
          [
            "d ${directories.state} 0750 hermes hermes - -"
            "d ${directories.home} 0750 hermes hermes - -"
            "d ${directories.workspace} 0750 hermes hermes - -"
          ]
          ++ (
            optional
            cfg.envSecret.enable
            "L+ ${directories.home}/.env - - - - ${envSecretPath}"
          );
      };

      sops = {
        secrets = optionalAttrs cfg.envSecret.enable {
          ${cfg.envSecret.name} = {
            owner = "hermes";
            group = "hermes";
            mode = "0400";
          };
        };
      };

      virtualisation = {
        docker.enable = true;
      };
    }));
  };
in {
  core = mk "core";
  home = mk "home";
}
