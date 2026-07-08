{
  lix,
  top,
  shared,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs recursiveUpdate;
  inherit (lix.lists) optional;
  inherit (lix.modules) mkDefault;
  inherit (lix.options) mkEnable mkModuleArgs mkOption;
  inherit (lix.types) anything attrs attrsOf bool int listOf nullOr package str submodule;

  name = "hermes";
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
      {"USER" = defaults.directories.docs + "/USER.md";}
      (staged.instructions or {});
  };

  resolved = {workspace ? defaults.directories.workspace, ...}: {
    settings = recursiveUpdate defaults.settings {
      terminal.cwd = workspace;
    };
  };

  module = {
    config,
    options,
    pkgs,
    ...
  }: let
    scope = "core";
    mod = mkModuleArgs {
      inherit config options top scope;
      path = ["services"];
    };
    opt = mod.set.options.module;
    cfg = config.${top}.services.ai.hermes;

    inherit
      (cfg)
      enable
      stateDirectory
      gatewayPackage
      dotsPackage
      container
      envSecret
      extraDependencyGroups
      settings
      instructions
      addToSystemPackages
      extraArgs
      restart
      restartSec
      ;
    inherit (pkgs) writeShellApplication;

    directories = let
      built = mkDirs stateDirectory;
      local = config.${top}.paths.local or {};
    in
      built // {root = local.src or (local.dots or built.workspace);};

    runtime = resolved {inherit (directories) workspace;};

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
          cd "''${DOTS:-${directories.root}}"
          exec hermes "$@"
        '';
      };
    };
  in {
    options = opt {
      ai.hermes = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options = {
            enable = mkEnable {
              inherit name;
              scope = "core";
              default = defaults.enable;
            };

            stateDirectory = mkOption {
              type = str;
              default = defaults.directories.state;
              description = "Persistent runtime root for the system Hermes instance. Rebuild-safe mutable state lives here rather than in the Nix store.";
            };

            gatewayPackage = mkOption {
              type = package;
              default = applications.gateway;
              description = "Wrapper package for running the system Hermes instance as the hermes user.";
            };

            dotsPackage = mkOption {
              type = package;
              default = applications.dots;
              description = "Wrapper package for launching Hermes from the dotfiles checkout.";
            };

            container = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options.enable = mkOption {
                  type = bool;
                  default = defaults.container.enable;
                  description = "Whether Hermes Agent should run inside its upstream container integration.";
                };
              };
              default = defaults.container;
              description = "Container integration settings for Hermes Agent.";
            };

            envSecret = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options = {
                  enable = mkEnable {
                    name = "hermes env secret";
                    scope = "core";
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
              };
              default = defaults.envSecret;
              description = "Staged sops-backed environment secret metadata for the Hermes service.";
            };

            extraDependencyGroups = mkOption {
              type = listOf str;
              default = defaults.extraDependencyGroups;
              description = "Hermes Agent optional dependency groups to install.";
            };

            settings = mkOption {
              type = attrs;
              default = runtime.settings;
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
        };
        default = {};
      };
    };

    config = optionalAttrs enable {
      assertions = [
        {
          assertion = !envSecret.enable || envSecret.path != null;
          message = "${top}.services.ai.hermes.envSecret.enable requires the secrets layer to materialize ${envSecret.name}.";
        }
      ];

      environment.systemPackages = [gatewayPackage dotsPackage];

      services.hermes-agent = {
        enable = mkDefault true;
        container.enable = mkDefault container.enable;
        extraDependencyGroups = mkDefault extraDependencyGroups;
        settings = mkDefault settings;
        environmentFiles = optional envSecret.enable envSecret.path;
        documents = mkDefault instructions;
        addToSystemPackages = mkDefault addToSystemPackages;
        extraArgs = mkDefault extraArgs;
        restart = mkDefault restart;
        restartSec = mkDefault restartSec;
      };

      systemd.services.hermes-agent.serviceConfig =
        {
          TimeoutStopSec = 240;
          UnsetEnvironment = ["MESSAGING_CWD"];
        }
        // optionalAttrs envSecret.enable {
          EnvironmentFile = envSecret.path;
        };

      systemd.tmpfiles.rules =
        [
          "d ${directories.state} 0750 hermes hermes - -"
          "d ${directories.home} 0750 hermes hermes - -"
          "d ${directories.workspace} 0750 hermes hermes - -"
        ]
        ++ optional envSecret.enable "L+ ${directories.home}/.env - - - - ${envSecret.path}";

      sops.secrets = optionalAttrs envSecret.enable {
        ${envSecret.name} = {
          owner = "hermes";
          group = "hermes";
          mode = "0400";
        };
      };

      virtualisation.docker.enable = true;
    };
  };
in {
  core = {};
  home = {};
}
