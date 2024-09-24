{
  inputs,
  pkgs,
  ...
}: {
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
      alsa.support32Bit = true; # Whether to enable 32-bit ALSA support on 64-bit systems.
      pulse.enable = true;
      jack.enable = true; # If you want to use JACK applications, uncomment this
      socketActivation = true; # Automatically run PipeWire when connections are made to the PipeWire socket.
    };
  };
  nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay]; # Automated, pre-built, (potentially) pre-release packages for Wayland (sway/wlroots) tools for NixOS.
  hardware.pulseaudio = {
    enable = false; # Disable PulseAudio to use PipeWire instead.
    support32Bit = true; # Enable 32-bit support for PulseAudio, if being used.
  };
  security.rtkit.enable = true; # Whether to enable the RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand. The PulseAudio server uses this to acquire realtime priority.
  hardware.graphics.enable32Bit = true; # On 64-bit systems, whether to also install 32-bit drivers for 32-bit applications (such as Wine).
  hardware.opengl.driSupport32Bit = true; # On 64-bit systems, whether to support Direct Rendering for 32-bit applications (such as Wine). This is currently only supported for the nvidia and ati_unfree drivers, as well as Mesa.
  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    amdvlk # Modern AMD Graphics Core Next (GCN) GPUs are supported through either radv, which is part of mesa, or the amdvlk package. Adding the amdvlk package to hardware.opengl.extraPackages makes both drivers available for applications and lets them choose.
    rocm-opencl-icd # Modern AMD Graphics Core Next (GCN) GPUs are supported through the rocm-opencl-icd package.
    rocm-runtime-ext # OpenCL Image support is provided through the non-free rocm-runtime-ext package.
  ];
  hardware.opengl.extraPackages32 = with pkgs; [
    driversi686Linux.amdvlk # The 32-bit AMDVLK drivers can be used in addition to the Mesa RADV drivers.
  ];
  hardware.enableRedistributableFirmware = true; # Whether to enable firmware with a license allowing redistribution.
  hardware.enableAllFirmware = true; # Whether to enable all firmware regardless of license.
  chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" # Most software has the HIP libraries hard-coded.
  ];
}
