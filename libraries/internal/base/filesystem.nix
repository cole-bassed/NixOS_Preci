_: let
  exports = {
    scoped = {
      ls = builtins.readDir;
      read = builtins.readFile;
      type = builtins.readFileType;
    };
    global = {
      inherit
        (builtins)
        baseNameOf
        currentSystem
        dirOf
        filterSource
        findFile
        path
        pathExists
        readDir
        readFile
        readFileType
        storeDir
        storePath
        toPath
        ;
    };
  };
in
  exports
