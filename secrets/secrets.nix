let
  systems = {
    thoughtful = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9vESx3ERRcW5yFFJBd+EEmyGluZGFLGBdq1Z4lyLt/";
    # Add other hosts here as needed:
    # eris = "ssh-ed25519 ...";
    # sedna = "ssh-ed25519 ...";
    # bubblegum = "ssh-ed25519 ...";
    # jupiter = "ssh-ed25519 ...";
  };

  users = {
    teq = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B";
  };

  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
in
{
  # WireGuard configuration for thoughtful
  "wg0.age".publicKeys = allUsers ++ [ systems.thoughtful ];

  # Add more secrets here as needed:
  # "example.age".publicKeys = allUsers ++ allSystems;
}