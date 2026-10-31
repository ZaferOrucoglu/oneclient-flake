{
  lib,
  fetchurl,
  appimageTools,
  libayatana-appindicator,
  libgpg-error,
}:

let
  pname = "oneclient";
  version = "2.9.0";

  src = fetchurl {
    url = "https://github.com/Polyfrost/OneLauncher/releases/download/oneclient-${version}/OneClient_${version}_linux_x86_64.AppImage";
    hash = "sha256-WvaXMht9bmYZaAJ1Qb8CLf3PEYEvzrEZq/3TKKTIV3E=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;
  contents = appimageContents;

  extraPkgs = pkgs: with pkgs; [
    libayatana-appindicator
    libgpg-error
    flite.lib
    libpulseaudio
    alsa-lib
    openal
    libGL
    libglvnd
    udev
    fontconfig
    freetype
    vulkan-loader
    libxtst
    libx11
    libxext
    libxcursor
    libxrandr
    libxxf86vm
    libxi
    libxinerama
    libxcomposite
    libxdamage
    libxfixes
    libxrender
    libxcb
    gamemode
    wayland
    libdecor
    libxkbcommon
    pciutils
  ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/oneclient_app.desktop $out/share/applications/oneclient.desktop
    substituteInPlace $out/share/applications/oneclient.desktop \
      --replace-fail "Exec=oneclient_app" "Exec=oneclient"
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  meta = with lib; {
    description = "Next-generation open source Minecraft launcher";
    homepage = "https://github.com/Polyfrost/OneLauncher";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "oneclient";
  };
}
