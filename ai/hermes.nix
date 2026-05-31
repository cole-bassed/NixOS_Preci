{
  config,
  inputs,
  dots,
  pkgs,
  ...
}: let
  inherit (inputs) hermes-agent;

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

  environment = {
    systemPackages = [hermesGateway dotsHermes];
  };

  services = {
    hermes-agent = {
      enable = true;

      container = {
        enable = false;
      };

      # ── Model ──────────────────────────────────────────────────────────
      extraDependencyGroups = [
        "messaging"
        "edge-tts"
      ];

      settings = {
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

      # ── Secrets ────────────────────────────────────────────────────────
      environmentFiles = [
        config.sops.secrets.${secrets.env}.path
      ];

      # ── Documents ──────────────────────────────────────────────────────
      documents = {
        "USER.md" = ./documents/USER.md;
      };

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
      addToSystemPackages = true;

      extraArgs = [
        # "--verbose"
      ];

      restart = "always";
      restartSec = 5;
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
}
