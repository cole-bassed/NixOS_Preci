{
  config,
  inputs,
  ...
}: let
  inherit (inputs) hermes-agent;

  secrets = {
    env = "services/hermes/env";
  };
in {
  imports = [
    hermes-agent.nixosModules.default
  ];

  services = {
    hermes-agent = {
      enable = true;

      # Keep local first. Enable container only after auth/model routing works.
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
          default = "gpt-5.5-codex";
        };

        toolsets = ["all"];

        max_turns = 100;

        terminal = {
          backend = "local";
          cwd = ".";
          timeout = 180;
        };

        compression = {
          enabled = true;
          threshold = 0.85;
          summary_model = "gpt-5.5-codex";
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
      # Not strictly required for openai-codex OAuth, but useful for optional
      # provider keys or service environment values later.
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

  sops = {
    secrets = {
      ${secrets.env} = {
        mode = "0400";
      };
    };
  };

  virtualisation.docker.enable = true;
}
