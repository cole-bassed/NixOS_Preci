{
  config,
  inputs,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrs bool enum int listOf nullOr package str;

  dom = "applications";
  mod = "zen-browser";

  cfg = config.${top}.${dom}.${mod};

  selectedUnwrappedPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}."${cfg.channel}-unwrapped";

  mkExtensionSettings = mapAttrs (_: pluginId: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
    installation_mode = "force_installed";
  });

  pins = {
    "GitHub" = {
      id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
      url = "https://github.com";
      position = 101;
    };
  };
in {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Zen Browser Home Manager profile";

    channel = mkOption {
      type = enum ["beta" "twilight" "twilight-official"];
      default = "twilight";
      description = "Zen Browser release channel/package to use.";
    };

    setAsDefaultBrowser = mkOption {
      type = bool;
      default = true;
      description = "Whether Zen should be set as the default browser by the upstream module.";
    };

    policies = mkOption {
      type = attrs;
      default = {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        Preferences = {
          "browser.startup.homepage" = {
            Value = "about:blank";
            Status = "locked";
          };
          "browser.tabs.warnOnClose" = {
            Value = true;
            Status = "locked";
          };
        };
        ExtensionSettings = mkExtensionSettings {
          "wappalyzer@crunchlabz.com" = "wappalyzer";
          "{85860b32-02a8-431a-b2b1-40fbd64c9c69}" = "github-file-icons";
        };
      };
      description = "Firefox policy-template settings applied to Zen through policies.json.";
    };

    nativeMessagingHosts = mkOption {
      type = listOf package;
      default = [pkgs.firefoxpwa];
      description = "Native messaging host packages exposed to Zen.";
    };

    profile = {
      name = mkOption {
        type = str;
        default = "default";
        description = "Zen profile name to configure.";
      };

      settings = mkOption {
        type = attrs;
        default = {
          "zen.workspaces.continue-where-left-off" = true;
          "zen.view.compact.hide-tabbar" = true;
          "zen.urlbar.behavior" = "float";
          "zen.welcome-screen.seen" = true;
        };
        description = "about:config preferences written to prefs.js for the configured profile.";
      };

      mods = mkOption {
        type = listOf str;
        default = [
          "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
          "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
          "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
          "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
          "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
          "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
        ];
        description = "Zen Store mod UUIDs installed into the configured profile.";
      };

      search = mkOption {
        type = attrs;
        default = {
          force = true;
          default = "ddg";
          engines = {
            mynixos = {
              name = "My NixOS";
              urls = [
                {
                  template = "https://mynixos.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@nx"];
            };
            github = {
              name = "GitHub Search";
              urls = [
                {
                  template = "https://github.com/search?q={searchTerms}";
                }
              ];
              definedAliases = ["@gh"];
            };
          };
        };
        description = "Search engines and defaults for the configured profile.";
      };

      bookmarks = mkOption {
        type = attrs;
        default = {
          force = true;
          settings = [
            {
              name = "Nix Sites";
              toolbar = true;
              bookmarks = [
                {
                  name = "homepage";
                  url = "https://nixos.org/";
                }
                {
                  name = "wiki";
                  tags = ["wiki" "nix"];
                  url = "https://wiki.nixos.org/";
                }
                {
                  name = "packages";
                  url = "https://search.nixos.org/packages";
                }
              ];
            }
            {
              name = "Development";
              bookmarks = [
                {
                  name = "GitHub";
                  url = "https://github.com";
                }
              ];
            }
          ];
        };
        description = "Declarative bookmarks for the configured profile.";
      };

      containersForce = mkOption {
        type = bool;
        default = true;
        description = "Whether to delete containers not declared in this module.";
      };

      containers = mkOption {
        type = attrs;
        default = {
          Personal = {
            color = "purple";
            icon = "fingerprint";
            id = 1;
          };
          Work = {
            color = "blue";
            icon = "briefcase";
            id = 2;
          };
          Shopping = {
            color = "yellow";
            icon = "dollar";
            id = 3;
          };
        };
        description = "Declarative Zen containers for the configured profile.";
      };

      spacesForce = mkOption {
        type = bool;
        default = true;
        description = "Whether to delete spaces not declared in this module.";
      };

      spaces = mkOption {
        type = attrs;
        default = {
          Personal = {
            id = "c6de089c-410d-4206-961d-ab11f988d40a";
            position = 1000;
            icon = "🏠";
          };
          Work = {
            id = "cdd10fab-4fc5-494b-9041-325e5759195b";
            position = 2000;
            icon = "💼";
            container = 2;
            theme = {
              type = "gradient";
              colors = [
                {
                  red = 100;
                  green = 150;
                  blue = 200;
                  algorithm = "floating";
                  type = "explicit-lightness";
                  lightness = 50;
                }
              ];
              opacity = 0.8;
              texture = 0.5;
            };
          };
          Shopping = {
            id = "78aabdad-8aae-4fe0-8ff0-2a0c6c4ccc24";
            position = 3000;
            icon = "💸";
            container = 3;
          };
        };
        description = "Declarative Zen spaces for the configured profile.";
      };

      pinsForce = mkOption {
        type = bool;
        default = true;
        description = "Whether to apply pinsForceAction to undeclared pinned tabs.";
      };

      pinsForceAction = mkOption {
        type = enum ["remove" "demote"];
        default = "remove";
        description = "Action to take for undeclared pinned tabs when pinsForce is enabled.";
      };

      pins = mkOption {
        type = attrs;
        default =
          pins
          // {
            Email = {
              id = "9d8a8f91-7e29-4688-ae2e-da4e49d4a179";
              url = "https://mail.protonmail.com";
              position = 100;
              isEssential = true;
            };
            "Dev Tools" = {
              id = "d85a9026-1458-4db6-b115-346746bcc692";
              isGroup = true;
              isFolderCollapsed = false;
              editedTitle = true;
              position = 200;
              folderIcon = "chrome://browser/skin/zen-icons/selectable/eye.svg";
            };
            "NixOS Packages" = {
              id = "f8dd784e-11d7-430a-8f57-7b05ecdb4c77";
              url = "https://search.nixos.org/packages";
              folderParentId = "d85a9026-1458-4db6-b115-346746bcc692";
              position = 201;
            };
            "NixOS Options" = {
              id = "92931d60-fd40-4707-9512-a57b1a6a3919";
              url = "https://search.nixos.org/options";
              folderParentId = "d85a9026-1458-4db6-b115-346746bcc692";
              position = 202;
            };
            Docs = {
              id = "a4b044aa-ec6e-4a0a-81bd-cf59c90ad0b7";
              url = "https://docs.zen-browser.app";
              position = 300;
            };
            Issues = {
              id = "eb41c041-f720-4702-a955-c163ef040e25";
              url = "https://github.com/zen-browser/desktop/issues";
              position = 301;
            };
          };
        description = "Declarative pinned tabs, groups, folders, and essentials.";
      };

      joinedTabs = mkOption {
        type = attrs;
        default = {
          "Docs and issues" = {
            id = "docs-issues-split";
            gridType = "vsep";
            tabs = [
              "a4b044aa-ec6e-4a0a-81bd-cf59c90ad0b7"
              "eb41c041-f720-4702-a955-c163ef040e25"
            ];
          };
        };
        description = "Zen split-view joined tab groups built from stable declared pin IDs.";
      };

      keyboardShortcutsVersion = mkOption {
        type = nullOr int;
        default = 17;
        description = "Expected Zen keyboard shortcut schema version.";
      };

      keyboardShortcuts = mkOption {
        type = listOf attrs;
        default = [
          {
            id = "zen-compact-mode-toggle";
            key = "c";
            modifiers = {
              control = true;
              alt = true;
            };
          }
          {
            id = "zen-toggle-sidebar";
            key = "x";
            modifiers = {
              control = true;
              alt = true;
            };
          }
          {
            id = "key_quitApplication";
            disabled = true;
          }
          {
            id = "key_reload";
            key = "r";
            modifiers.control = true;
          }
          {
            id = "key_reload_skip_cache";
            key = "r";
            modifiers = {
              control = true;
              shift = true;
            };
          }
        ];
        description = "Declarative keyboard shortcut overrides for the configured profile.";
      };

      userChrome = mkOption {
        type = str;
        default = ''
          #navigator-toolbox {
            background-color: #2b2b2b;
          }

          #TabsToolbar {
            min-height: 28px;
          }

          .tab-icon-image {
            width: 16px;
            height: 16px;
          }
        '';
        description = "Custom userChrome.css content for Zen UI customization.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.zen-browser = {
      enable = mkDefault true;
      setAsDefaultBrowser = mkDefault cfg.setAsDefaultBrowser;
      policies = mkDefault cfg.policies;
      nativeMessagingHosts = mkDefault cfg.nativeMessagingHosts;
      unwrappedPackage = mkDefault selectedUnwrappedPackage;

      profiles.${cfg.profile.name} = {
        settings = mkDefault cfg.profile.settings;
        mods = mkDefault cfg.profile.mods;
        search = mkDefault cfg.profile.search;
        bookmarks = mkDefault cfg.profile.bookmarks;
        containersForce = mkDefault cfg.profile.containersForce;
        containers = mkDefault cfg.profile.containers;
        spacesForce = mkDefault cfg.profile.spacesForce;
        spaces = mkDefault cfg.profile.spaces;
        pinsForce = mkDefault cfg.profile.pinsForce;
        pinsForceAction = mkDefault cfg.profile.pinsForceAction;
        pins = mkDefault cfg.profile.pins;
        joinedTabs = mkDefault cfg.profile.joinedTabs;
        keyboardShortcutsVersion = mkDefault cfg.profile.keyboardShortcutsVersion;
        keyboardShortcuts = mkDefault cfg.profile.keyboardShortcuts;
        userChrome = mkDefault cfg.profile.userChrome;
      };
    };
  };
}
