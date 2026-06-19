_: let
  exports = {
    scoped = {
      from = with builtins; {
        json = fromJSON;
        toml = fromTOML;
      };

      to = with builtins; {
        json = toJSON;
        xml = toXML;
        file = toFile;
        string = toString;
        path = toPath;
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
