{
  mkLibs,
  libraries,
}:
mkLibs {
  inherit libraries;
  prefix = ["config"];
  specs = [
    {
      input = ./assembly.nix;
      dependencies = [
        "api"
        "attrsets"
        "debug"
        "lists"
        "strings"
        "types"
        "environment"
        "names"
        "paths"
        "defaults"
        "external"
        "systems"
        "flake"
      ];
    }
    {
      input = ./environment.nix;
      dependencies = [
        "flake"
        "names"
        "paths"
        "defaults"
        "external"
        "api"
        "attrsets"
        "debug"
        "lists"
        "strings"
        "types"
      ];
    }
    {
      input = ./ingestion.nix;
      dependencies = [
        "attrsets"
        "filesystem"
        "lists"
        "defaults"
        "strings"
        "types"
      ];
    }
    {
      input = ./systems.nix;
      dependencies = [
        "api"
        "flake"
        "defaults"
        "external"
        "attrsets"
        "debug"
        "lists"
        "strings"
        "types"
      ];
    }
    {
      input = ./users.nix;
      dependencies = [
        "attrsets"
        "environment"
        "ingestion"
        "lists"
        "strings"
      ];
    }
  ];
}
