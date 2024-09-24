{...}: {
  users.users.teq = {
    isNormalUser = true;
    description = "Teq";
    extraGroups = ["networkmanager" "wheel" "audio" "docker"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
    ];
  };
}
