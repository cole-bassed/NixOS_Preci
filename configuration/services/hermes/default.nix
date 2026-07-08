{
  lib,
  lix,
  stagedServices,
  top,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs bool int listOf nullOr package str submodule;
  inherit (lix.options) mkModuleArgs;

  dom = "services";
  mod = "hermes";

  staged = stagedServices.hermes or {};
  stagedContainer = staged.container or {};
  stagedEnvSecret = staged.envSecret or {};

  mk = scope: {
    config,
    dots,
    pkgs,
    ...
  }: let
    module = mkModuleArgs {inherit config top dom mod scope;};
    cfg = module.get.config.module;
    opt = module.set.options.module;
    mkEnable = default: module.set.enable {inherit default;};
    repoRoot =
      config.${top}.paths.local.src
      or config.${top}.paths.local.dots
      or "/var/lib/hermes/workspace";

    hermesGateway = pkgs.writeShellApplication {
      name = "hermes-gateway";
      text = ''
        exec /run/wrappers/bin/sudo -u hermes \
          env \
            HERMES_HOME=/var/lib/hermes/.hermes \
            HOME=/var/lib/hermes \
            /run/current-system/sw/bin/hermes "$@"
      '';
    };

    dotsHermes = pkgs.writeShellApplication {
      name = "dots-hermes";
      text = ''
        unset HERMES_HOME
        cd "''${DOTS:-${repoRoot}}"
        exec hermes "$@"
      '';
    };
  in {
    options = opt {
      enable = mkEnable (staged.enable or false);

      gatewayPackage = mkOption {
        type = package;
        default = hermesGateway;
        description = "Wrapper package for running the system Hermes instance as the hermes user.";
      };

      dotsPackage = mkOption {
        type = package;
        default = dotsHermes;
        description = "Wrapper package for launching Hermes from the dotfiles checkout.";
      };

      container.enable = mkOption {
        type = bool;
        default = stagedContainer.enable or false;
        description = "Whether Hermes Agent should run inside its upstream container integration.";
      };

      envSecret = mkOption {
        type = submodule {
          options = {
            enable = mkEnable (stagedEnvSecret.enable or staged.enable or false);
            name = mkOption {
              type = str;
              default = stagedEnvSecret.name or "services/hermes/env";
              description = "Logical sops secret name that stores the Hermes environment file for this host.";
            };
            path = mkOption {
              type = nullOr str;
              default = null;
              description = "Resolved filesystem path for the decrypted Hermes environment file, materialized by the secrets layer.";
            };
          };
        };
        default = stagedEnvSecret;
        description = "Staged sops-backed environment secret metadata for the Hermes service.";
      };

      extraDependencyGroups = mkOption {
        type = listOf str;
        default = [
          "messaging"
          "edge-tts"
        ];
        description = "Hermes Agent optional dependency groups to install.";
      };

      settings = mkOption {
        type = attrs;
        default = {
          model = {
            provider = "openai-codex";
            default = "gpt-5.5";
          };

          toolsets = ["all"];
          max_turns = 100;

          terminal = {
            backend = "local";
            cwd = "/var/lib/hermes/workspace";
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
        };
        description = "Hermes Agent config.yaml settings rendered by the NixOS module.";
      };

      documents = mkOption {
        type = attrs;
        default = {
          "USER.md" = ./documents/USER.md;
        };
        description = "Documents linked into Hermes Agent context.";
      };

      addToSystemPackages = mkOption {
        type = bool;
        default = true;
        description = "Whether the upstream Hermes package should be added to system packages.";
      };

      extraArgs = mkOption {
        type = listOf str;
        default = [
          # "--verbose"
        ];
        description = "Extra command-line arguments passed to the Hermes Agent service.";
      };

      restart = mkOption {
        type = str;
        default = "always";
        description = "Systemd Restart policy for the Hermes Agent service.";
      };

      restartSec = mkOption {
        type = int;
        default = 5;
        description = "Seconds to wait before restarting the Hermes Agent service.";
      };
    };

    config =
      if scope == "core"
      then
        mkIf cfg.enable {
          assertions = [
            {
              assertion = !cfg.envSecret.enable || cfg.envSecret.path != null;
              message = "${top}.services.hermes.envSecret.enable requires the secrets layer to materialize ${cfg.envSecret.name}.";
            }
          ];

          environment.systemPackages = [
            cfg.gatewayPackage
            cfg.dotsPackage
          ];

          services.hermes-agent = {
            enable = mkDefault true;

            container.enable = mkDefault cfg.container.enable;
            extraDependencyGroups = mkDefault cfg.extraDependencyGroups;
            settings = mkDefault cfg.settings;
            environmentFiles = optional cfg.envSecret.enable cfg.envSecret.path;
            documents = mkDefault cfg.documents;

            addToSystemPackages = mkDefault cfg.addToSystemPackages;
            extraArgs = mkDefault cfg.extraArgs;
            restart = mkDefault cfg.restart;
            restartSec = mkDefault cfg.restartSec;
          };

          systemd.services.hermes-agent.serviceConfig = {
            TimeoutStopSec = 240;
            UnsetEnvironment = ["MESSAGING_CWD"];
          } // optionalAttrs cfg.envSecret.enable {
            EnvironmentFile = cfg.envSecret.path;
          };

          systemd.tmpfiles.rules = [
            "d /var/lib/hermes 0750 hermes hermes - -"
            "d /var/lib/hermes/.hermes 0750 hermes hermes - -"
            "d /var/lib/hermes/workspace 0750 hermes hermes - -"
          ] ++ optional cfg.envSecret.enable "L+ /var/lib/hermes/.hermes/.env - - - - ${cfg.envSecret.path}";

          sops.secrets = optionalAttrs cfg.envSecret.enable {
            ${cfg.envSecret.name} = {
              owner = "hermes";
              group = "hermes";
              mode = "0400";
            };
          };

          virtualisation.docker.enable = true;
        }
      else {};
  };
in {
  core = mk "core";
  home = mk "home";
}
