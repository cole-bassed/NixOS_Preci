{api, ...}: let
  exports = {
    scoped = {inherit registry;};
    global = {interfaceAPI = registry;};
  };

  registry = api.interface;
in
  exports
