{...}: {
  home-manager.users.teq.teq.home-manager.gui = true;
  teq.nixos = {
    gui.enable = true;
    gui.amd = true;
    gui.steam = true;
  };
}
