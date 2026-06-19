{
  config,
  dots,
  inputs,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  inherit (inputs) hermes-agent;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs bool int listOf package str;
  inherit (lix) mkModuleArgs;

  dom = "ai";
  mod = "hermes";

  inherit (mkModuleArgs {inherit config top dom mod;}) cfg opt mkEnableMod;

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
      cd "''${DOTS:-${dots}}"
      exec hermes "$@"
    '';
  };

  secrets.env = "services/hermes/env";
in {
  imports = [hermes-agent.nixosModules.default];

  options = opt {
    enable = mkEnableMod.true;

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
      default = false;
      description = "Whether Hermes Agent should run inside its upstream container integration.";
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

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        cfg.gatewayPackage
        cfg.dotsPackage
      ];
    };

    services = {
      hermes-agent = {
        enable = mkDefault true;

        container = {
          enable = mkDefault cfg.container.enable;
        };

        # ── Model ──────────────────────────────────────────────────────────
        extraDependencyGroups = mkDefault cfg.extraDependencyGroups;

        settings = mkDefault cfg.settings;

        # ── Secrets ────────────────────────────────────────────────────────
        environmentFiles = [
          config.sops.secrets.${secrets.env}.path
        ];

        # ── Documents ──────────────────────────────────────────────────────
        documents = mkDefault cfg.documents;

        # ── MCP Servers ────────────────────────────────────────────────────
        # mcpServers.filesystem = {
        #   command = "npx";
        #   args = [
        #     "-y"
        #     "@modelcontextprotocol/server-filesystem"
        #     "/home/craole/.dots"
        #   ];
        # };

        # ── Container options ──────────────────────────────────────────────
        # container = {
        #   enable = true;
        #   image = "ubuntu:24.04";
        #   backend = "docker";
        #   extraVolumes = [
        #     "/home/craole/.dots:/dots:rw"
        #     "/home/craole/Projects:/projects:rw"
        #   ];
        # };

        # ── Service tuning ─────────────────────────────────────────────────
        addToSystemPackages = mkDefault cfg.addToSystemPackages;

        extraArgs = mkDefault cfg.extraArgs;

        restart = mkDefault cfg.restart;
        restartSec = mkDefault cfg.restartSec;
      };
    };

    systemd = {
      services = {
        hermes-agent = {
          serviceConfig = {
            EnvironmentFile = config.sops.secrets.${secrets.env}.path;
            TimeoutStopSec = 240;
            UnsetEnvironment = [
              "MESSAGING_CWD"
            ];
          };
        };
      };

      tmpfiles = {
        rules = [
          "d /var/lib/hermes 0750 hermes hermes - -"
          "d /var/lib/hermes/.hermes 0750 hermes hermes - -"
          "d /var/lib/hermes/workspace 0750 hermes hermes - -"
          "L+ /var/lib/hermes/.hermes/.env - - - - ${config.sops.secrets.${secrets.env}.path}"
        ];
      };
    };

    sops = {
      secrets = {
        ${secrets.env} = {
          owner = "hermes";
          group = "hermes";
          mode = "0400";
        };
      };
    };

    virtualisation = {
      docker = {
        enable = true;
      };
    };
  };
}
