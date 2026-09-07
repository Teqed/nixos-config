{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.gui.enable {
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        socketActivation = true;
      };
    };
    services.pulseaudio = {
      enable = false;
      support32Bit = true;
    };
    security.rtkit.enable = true;
  };
}
