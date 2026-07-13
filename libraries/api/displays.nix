{
  attrsets,
  lists,
  strings,
  api,
  ...
}: let
  exports = {
    scoped = {inherit registry resolve;};
    global = {
      displayRegistry = registry;
      resolveDisplays = resolve;
    };
  };

  inherit (attrsets) listToAttrs mapAttrs mapAttrsToList;
  inherit (lists) elemAt foldl' length imap0 isList sort;
  inherit (strings) isString splitString toInt;

  registry = api.displays;

  resolve = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";
    raw = (host.devices or {}).display or [];

    cleanDisplay = display:
      removeAttrs display [
        "display"
        "monitor"
        "name"
        "output"
        "tags"
      ];

    parseSize = resolution: let
      parts = splitString "x" resolution;
    in {
      width = toInt (elemAt parts 0);
      height = toInt (elemAt parts 1);
    };

    parsePoint = position: let
      parts = splitString "x" position;
    in {
      x = toInt (elemAt parts 0);
      y = toInt (elemAt parts 1);
    };

    isPoint = position:
      isString position && length (splitString "x" position) == 2;

    resolveDisplay = idx: cfg: let
      output =
        cfg.output
        or (fail "display at index ${toString idx} missing 'output'");

      display =
        if cfg ? display || cfg ? monitor
        then let
          name =
            cfg.display
            or (cfg.monitor or (
              fail "display '${output}' missing 'display'"
            ));
        in
          registry.${name}
          or (fail "display '${output}' references unknown display '${name}'")
        else cfg;

      merged =
        cleanDisplay display
        // {
          enable = cfg.enable or true;
          priority = cfg.priority or idx;
          primary = cfg.primary or (idx == 0);
          position = cfg.position or "right";
        }
        // (removeAttrs cfg ["display" "monitor" "output"]);

      size =
        if (merged.resolution or null) != null
        then parseSize merged.resolution
        else {
          width = 0;
          height = 0;
        };
    in {
      name = output;
      value =
        merged
        // {
          layout = {
            inherit size;
            position = {
              x = 0;
              y = 0;
            };
          };
        };
    };

    resolved =
      if isList raw
      then listToAttrs (imap0 resolveDisplay raw)
      else
        mapAttrs
        (output: cfg:
          (resolveDisplay 0 (cfg // {inherit output;})).value)
        raw;

    ordered =
      sort
      (a: b: a.value.priority < b.value.priority)
      (mapAttrsToList (name: value: {inherit name value;}) resolved);

    leftWidth =
      foldl'
      (total: item:
        if item.value.position == "left"
        then total + item.value.layout.size.width
        else total)
      0
      ordered;

    topHeight =
      foldl'
      (total: item:
        if item.value.position == "top"
        then total + item.value.layout.size.height
        else total)
      0
      ordered;

    place = item: let
      display = item.value;
      inherit (display) position;

      point =
        if position == null
        then {
          x = 0;
          y = 0;
        }
        else if isPoint position
        then parsePoint position
        else if position == "left"
        then {
          x = 0;
          y = topHeight;
        }
        else if position == "right"
        then {
          x = leftWidth;
          y = topHeight;
        }
        else if position == "top"
        then {
          x = 0;
          y = 0;
        }
        else if position == "bottom"
        then {
          x = 0;
          y = topHeight;
        }
        else if position == "center"
        then {
          x = leftWidth;
          y = topHeight;
        }
        else fail "display '${item.name}' has invalid position '${position}'";
    in {
      inherit (item) name;
      value =
        display
        // {layout = (display.layout or {}) // {position = point;};};
    };
  in
    listToAttrs (map place ordered);
in
  exports
