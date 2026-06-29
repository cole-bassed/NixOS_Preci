{
  lib,
  mkArgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs bool enum;

  githubPin = {
    "GitHub" = {
      id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
      url = "https://github.com";
      position = 101;
    };
  };
in {
  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) opt;
  in {
    options = opt {
      profile.pinsForce = mkOption {
        type = bool;
        default = true;
        description = "Whether to apply pinsForceAction to undeclared pinned tabs.";
      };
      profile.pinsForceAction = mkOption {
        type = enum ["remove" "demote"];
        default = "remove";
        description = "Action to take for undeclared pinned tabs when pinsForce is enabled.";
      };
      profile.pins = mkOption {
        type = attrs;
        default =
          githubPin
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
      profile.joinedTabs = mkOption {
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
    };
  };
}
