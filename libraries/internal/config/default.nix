{mkLibNested, ...}:
mkLibNested {
  dependencies = {
    assembly = [
      "api"
      "debug"
      "attrsets"
      "modules"
      "lists"
      "strings"
      "system"
      "environment"
    ];

    environment = [
      "api"
      "attrsets"
      "debug"
      "strings"
      "types"
    ];

    ingestion = [
      "attrsets"
      "filesystem"
      "lists"
      "strings"
      "types"
    ];

    system = [
      "api"
      "attrsets"
      "debug"
      "lists"
      "strings"
      "types"
    ];

    users = [
      "attrsets"
      "environment"
      "importers"
      "lists"
      "strings"
    ];
  };

  modules = {
    assembly = ./assembly.nix;
    environment = ./environment.nix;
    ingestion = ./ingestion.nix;
    system = ./system.nix;
    users = ./users.nix;
  };
}
