{libraries, ...} @ base:
libraries.assemble.configurations base {
  modules.core = [
    ({host, ...}: {
      system.stateVersion = host.stateVersion or null;
      # config.system.stateVersion = config.system.nixos.release;
    })
  ];
}
