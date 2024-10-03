{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos.desktop.audio;
in {
  options.teq.nixos.desktop = {
    audio = lib.mkEnableOption "Teq's NixOS Desktop Audio configuration defaults.";
  };
  config = lib.mkIf cfg.enable {
    services = {
      pipewire = {
        enable = true; # Enable sound with pipewire.
        alsa.enable = true;
        alsa.support32Bit = true; # Whether to enable 32-bit ALSA support on 64-bit systems.
        pulse.enable = true;
        jack.enable = true; # If you want to use JACK applications, uncomment this
        socketActivation = true; # Automatically run PipeWire when connections are made to the PipeWire socket.
      };
    };
    hardware.pulseaudio = {
      enable = false; # Disable PulseAudio to use PipeWire instead.
      support32Bit = true; # Enable 32-bit support for PulseAudio, if being used.
    };
    security.rtkit.enable = true; # Whether to enable the RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand. The PulseAudio server uses this to acquire realtime priority.
  };
}
