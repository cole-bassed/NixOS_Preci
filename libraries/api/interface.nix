{collections, ...}: let
  exports = {
    scoped = {inherit registry;};
    global = {interfaceAPI = registry;};
  };

  registry = collections.interface;
in
  exports
