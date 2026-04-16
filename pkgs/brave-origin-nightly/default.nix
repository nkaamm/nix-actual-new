{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  snappy,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  libxcb,
  zlib,

  # command line arguments which are always set e.g "--disable-gpu"
  commandLineArgs ? "",

  # Necessary for USB audio devices.
  pulseSupport ? stdenv.hostPlatform.isLinux,
  libpulseaudio,

  # For GPU acceleration support on Wayland
  libGL,

  # For video acceleration via VA-API
  libvaSupport ? stdenv.hostPlatform.isLinux,
  libva,
  enableVideoAcceleration ? libvaSupport,

  # For Vulkan support; disabled by default as it seems to break VA-API
  vulkanSupport ? false,
  addDriverRunpath,
  enableVulkan ? vulkanSupport,
}:

let
  version = "1.91.56";

  inherit (lib)
    optional
    optionals
    makeLibraryPath
    makeSearchPathOutput
    makeBinPath
    optionalString
    strings
    escapeShellArg
    ;

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libx11
    libGL
    libxkbcommon
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pipewire
    udev
    wayland
    libxcb
    zlib
    snappy
    libkrb5
  ]
  ++ optional pulseSupport libpulseaudio
  ++ optional libvaSupport libva;

  rpath = makeLibraryPath deps + ":" + makeSearchPathOutput "lib" "lib64" deps;
  binpath = makeBinPath deps;

  enableFeatures =
    optionals enableVideoAcceleration [
      "AcceleratedVideoDecodeLinuxGL"
      "AcceleratedVideoEncoder"
    ]
    ++ optional enableVulkan "Vulkan";

  disableFeatures = [
    "OutdatedBuildDetector"
  ]
  ++ optionals enableVideoAcceleration [ "UseChromeOSDirectVideoDecoder" ];

in
stdenv.mkDerivation {
  pname = "brave-origin-nightly";
  inherit version;

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin-nightly_${version}_amd64.deb";
    hash = "sha256-gaZHbwe5K78DnrvAMdye0X6Xlo5ksxYNk6A2wFpxJzY=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = true;

  nativeBuildInputs = [
    dpkg
    (buildPackages.wrapGAppsHook3.override { makeWrapper = buildPackages.makeShellWrapper; })
  ];

  buildInputs = [
    glib
    gsettings-desktop-schemas
    gtk3
    gtk4
    adwaita-icon-theme
  ];

  unpackPhase = ''
    ar x $src
    tar xf data.tar.xz --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin

    cp -R usr/share $out
    cp -R opt/ $out/opt

    export BINARYWRAPPER=$out/opt/brave.com/brave-origin-nightly/brave-origin-nightly

    # Fix path to bash in wrapper script
    substituteInPlace $BINARYWRAPPER \
        --replace-fail /bin/bash ${stdenv.shell} \
        --replace-fail 'CHROME_WRAPPER' 'WRAPPER'

    ln -sf $BINARYWRAPPER $out/bin/brave-origin-nightly

    # The actual browser binary is usually named 'brave' or 'brave-origin'
    # We find all ELF files in the directory to be safe
    find $out/opt/brave.com/brave-origin-nightly -type f -executable | while read exe; do
      if patchelf --print-interpreter "$exe" >/dev/null 2>&1; then
        patchelf \
          --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${rpath}" "$exe"
      fi
    done

    # Fix .desktop file paths
    # We use a more generic substitution to handle different potential upstream paths
    for f in $out/share/applications/*.desktop; do
      if [ -f "$f" ]; then
        substituteInPlace "$f" \
            --replace-warn /usr/bin/brave-origin-nightly $out/bin/brave-origin-nightly \
            --replace-warn /usr/bin/brave-browser-nightly $out/bin/brave-origin-nightly \
            --replace-warn brave-origin-nightly $out/bin/brave-origin-nightly \
            --replace-warn /opt/brave.com $out/opt/brave.com
      fi
    done

    # Fix gnome-control-center default-apps if present
    if [ -f $out/share/gnome-control-center/default-apps/brave-origin-nightly.xml ]; then
      substituteInPlace $out/share/gnome-control-center/default-apps/brave-origin-nightly.xml \
          --replace-warn /opt/brave.com $out/opt/brave.com
    fi

    # Fix default-app-block if present
    if [ -f $out/opt/brave.com/brave-origin-nightly/default-app-block ]; then
      substituteInPlace $out/opt/brave.com/brave-origin-nightly/default-app-block \
          --replace-warn /opt/brave.com $out/opt/brave.com
    fi

    # Correct icons location
    icon_sizes=("16" "24" "32" "48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}; do
        mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
        if [ -f $out/opt/brave.com/brave-origin-nightly/product_logo_$icon.png ]; then
          ln -s $out/opt/brave.com/brave-origin-nightly/product_logo_$icon.png \
              $out/share/icons/hicolor/$icon\x$icon/apps/brave-origin-nightly.png
        fi
    done

    # Replace xdg-settings and xdg-mime
    ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/brave.com/brave-origin-nightly/xdg-settings
    ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/brave.com/brave-origin-nightly/xdg-mime

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${binpath}
      --suffix PATH : ${lib.makeBinPath [ xdg-utils coreutils ]}
      --set CHROME_WRAPPER brave-origin-nightly
      ${optionalString (enableFeatures != [ ]) ''
        --add-flags "--enable-features=${strings.concatStringsSep "," enableFeatures}\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+,WaylandWindowDecorations --enable-wayland-ime=true}}"
      ''}
      ${optionalString (disableFeatures != [ ]) ''
        --add-flags "--disable-features=${strings.concatStringsSep "," disableFeatures}"
      ''}
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
      ${optionalString vulkanSupport ''
        --prefix XDG_DATA_DIRS  : "${addDriverRunpath.driverLink}/share"
      ''}
      --add-flags ${escapeShellArg commandLineArgs}
    )
  '';

  installCheckPhase = ''
    $out/opt/brave.com/brave-origin-nightly/brave-origin-nightly --version
  '';

  meta = {
    homepage = "https://brave.com/";
    description = "Brave Origin Browser (Nightly) — a slimmer, privacy-focused variant of Brave";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "brave-origin-nightly";
  };
}
