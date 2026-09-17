{
  runCommand,
  weston,
  mesa,
  makeFontsConf,
  dejavu_fonts,
  coreutils,
  gnugrep,
  ghostty,
}:
runCommand "ghostty-shader-probe-${ghostty.version}"
  {
    nativeBuildInputs = [
      weston
      coreutils
      gnugrep
    ];
    FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ dejavu_fonts ]; };
    __EGL_VENDOR_LIBRARY_FILENAMES = "${mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
    LIBGL_DRIVERS_PATH = "${mesa}/lib/dri";
    LIBGL_ALWAYS_SOFTWARE = "1";
    EGL_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
  }
  ''
    export HOME=$TMPDIR/home XDG_RUNTIME_DIR=$TMPDIR/run
    mkdir -p $HOME $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR

    cat > shader.glsl <<'EOF'
    void mainImage(out vec4 fragColor, in vec2 fragCoord)
    {
      fragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    EOF

    weston --backend=headless --renderer=pixman --socket=probe \
      --width=640 --height=480 --idle-time=0 >weston.log 2>&1 &
    for _ in $(seq 50); do
      [ -S $XDG_RUNTIME_DIR/probe ] && break
      sleep 0.1
    done
    export WAYLAND_DISPLAY=probe

    timeout 10 ${ghostty}/bin/ghostty \
      --config-default-files=false \
      --gtk-single-instance=false \
      --custom-shader=$PWD/shader.glsl \
      -e sh -c 'sleep 5' >ghostty.log 2>&1 || true
    kill %1 || true

    if ! grep -q 'started subcommand' ghostty.log; then
      result=inconclusive
    elif grep -q 'error drawing' ghostty.log; then
      result=broken
    else
      result=fixed
    fi
    echo "probe result: $result"
    [ $result = inconclusive ] && cat weston.log ghostty.log
    printf %s $result > $out
  ''
