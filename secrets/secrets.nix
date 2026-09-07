let
  systems = {
    thoughtful = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9vESx3ERRcW5yFFJBd+EEmyGluZGFLGBdq1Z4lyLt/";
    bubblegum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IZpWJ13UifP6520LBn8+DA28XPBycCaupUxMP54m/";
  };

  users = {
    teq = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B";
  };

  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
in
{
  "wg0.age".publicKeys = allUsers ++ [ systems.thoughtful ];
  "gh.age".publicKeys = allUsers ++ allSystems;
  "washing-machien.age".publicKeys = allUsers ++ [ systems.thoughtful ];
  "mail-key-agent-bubblegum.age".publicKeys = allUsers ++ [ systems.bubblegum ];
  "gh-agent.age".publicKeys = allUsers ++ allSystems;
  "openai-agent-thoughtful.age".publicKeys = allUsers ++ [ systems.thoughtful ];
  "openai-agent-bubblegum.age".publicKeys = allUsers ++ [ systems.bubblegum ];
  "prime-agent-thoughtful.age".publicKeys = allUsers ++ [ systems.thoughtful ];
  "prime-agent-bubblegum.age".publicKeys = allUsers ++ [ systems.bubblegum ];
}
