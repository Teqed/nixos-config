let
  systems = {
    thoughtful = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9vESx3ERRcW5yFFJBd+EEmyGluZGFLGBdq1Z4lyLt/";
    bubblegum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IZpWJ13UifP6520LBn8+DA28XPBycCaupUxMP54m/";
    jupiter = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIm15NnzrBTMXTexLwFKEAHR4sAIHTawNaepnMemnkC7";
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
  "tailscale-auth.age".publicKeys = allUsers ++ allSystems;
  "cloudflare-ro.age".publicKeys = allUsers;
  "cloudflare-dns.age".publicKeys = allUsers ++ [ systems.jupiter ];
  "tranquil-env.age".publicKeys = allUsers ++ [ systems.jupiter ];
  "claude-agent.age".publicKeys = allUsers ++ allSystems;
  "codex-auth.age".publicKeys = allUsers ++ allSystems;
  "prime-auth.age".publicKeys = allUsers ++ allSystems;
  "ratlogin-headscale.age".publicKeys = allUsers ++ [ systems.jupiter ];
}
