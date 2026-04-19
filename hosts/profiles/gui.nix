{...}: {
  home-manager.users.teq.teq.home-manager.gui = true;
  home-manager.users.teq.teq.home-manager.dev = true;
  teq.nixos = {
    gui.enable = true;
    gui.amd = true;
    gui.steam = true;
  };
}
