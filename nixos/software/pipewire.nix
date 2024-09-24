{...}: {
  services = {
    pipewire = {
      # Enable sound with pipewire.
      enable = true;
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
}
