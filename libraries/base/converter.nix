_: let
  exports = {
    scoped = {
      from = {
        json = builtins.fromJSON;
        toml = builtins.fromTOML;
      };

      to = {
        json = builtins.toJSON;
        xml = builtins.toXML;
        file = builtins.toFile;
        string = builtins.toString;
        path = builtins.toPath;
      };
    };

    global = {
      inherit
        (builtins)
        fromJSON
        fromTOML
        toFile
        toJSON
        toPath
        toString
        toXML
        ;
    };
  };
in
  exports
