{mkLibNested, ...}:
mkLibNested {
  dependencies = {
    assembly = ["attrsets" "modules" "lists" "strings" "system" "environment"];
    environment = ["attrsets" "debug" "strings" "types"];
    importers = ["attrsets" "filesystem" "lists" "strings" "types"];
    system = ["attrsets" "debug" "lists" "strings" "types"];
    users = ["attrsets" "environment" "importers" "lists" "strings"];
  };
  modules = {
    assembly = ./assembly.nix;
    environment = ./environment.nix;
    importers = ./importers.nix;
    system = ./system.nix;
    users = ./users.nix;
  };
}
