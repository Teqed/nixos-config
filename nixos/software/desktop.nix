{...}: {
  imports = [
    ./steam.nix
  ];
  services = {
    xserver = {
      enable = true; # You can disable the X11 windowing system if you're only using the Wayland session.
      xkb = {
        # Configure keymap in X11
        layout = "us";
        variant = "";
      };
      # libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).
    };
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    printing.enable = true; # Enable CUPS to print documents.
    pipewire = {
      # Enable sound with pipewire.
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true; # If you want to use JACK applications, uncomment this
      socketActivation = true; # Automatically run PipeWire when connections are made to the PipeWire socket.
    };
  };
  hardware.pulseaudio.enable = false; # Disable PulseAudio to use PipeWire instead.
  security.rtkit.enable = true; # Whether to enable the RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand. The PulseAudio server uses this to acquire realtime priority.
  hardware.graphics.enable32Bit = true; # On 64-bit systems, whether to also install 32-bit drivers for 32-bit applications (such as Wine).
  chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
}
