{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.enable {
    systemd.user.startServices = lib.mkDefault "sd-switch";
    services = {
    };
    programs = {
    };

    home.packages = with pkgs; [
      acl
      attr
      bzip2
      coreutils-full
      cpio
      curl
      diffutils
      findutils
      gawk
      stdenv.cc.libc
      getent
      getconf
      gnugrep
      gnupatch
      gnused
      gnutar
      gzip
      xz
      less
      libcap
      ncurses
      netcat
      mkpasswd
      procps
      su
      time
      util-linux
      which
      zstd
      perl
      rsync
      strace
    ];
  };
}
