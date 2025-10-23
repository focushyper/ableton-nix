{ stdenv
, lib
, mkWindowsApp
, wine
, winetricks
, fetchurl
, makeDesktopItem
, makeDesktopIcon
, copyDesktopItems
, copyDesktopIcons
, unzip
, makeWrapper }:

mkWindowsApp rec {
  inherit wine;

  pname = "ableton";
  version = "12.2.6";

  src = builtins.fetchurl {
    url = "https://cdn-downloads.ableton.com/channels/${version}/ableton_live_suite_${version}_64.zip";
    sha256 = "1hlfxg67zlcblvfy41yw3m5v518fv1a8v2ghf2wf7xy5iysxp8j7";
  };

  dontUnpack = true;
  wineArch = "win64";
  enableInstallNotification = true;
  persistRegistry = true;
  persistRuntimeLayer = true;
  fileMapDuringAppInstall = true;
  inputHashMethod = "store-path";

  fileMap = {
    "$HOME/.config/Ableton" = "drive_c/users/$USER/AppData/Roaming/Ableton";
  };

  buildInputs = [ copyDesktopItems copyDesktopIcons unzip winetricks ];

  winAppInstall = ''
    d="$WINEPREFIX/drive_c/${pname}_install"
    PATH="$PATH:${lib.makeBinPath [ unzip winetricks ]}"

    mkdir -p "$d"
    unzip ${src} -d "$d"

    # --- install required dependencies ---
    "${winetricks}/bin/winetricks" -q corefonts tahoma vcrun2019 gdiplus dotnet48

    # --- run the actual Ableton installer ---
    wine "$d/Ableton Live 12 Suite Installer.exe"

    rm -rf "$d"
  '';

  winAppPreRun = ''
  '';

  winAppRun = ''
    wine "$WINEPREFIX/drive_c/ProgramData/Ableton/Live 12 Suite/Program/Ableton Live 12 Suite.exe"
  '';

  winAppPostRun = "";

  installPhase = ''
    runHook preInstall
    ln -s $out/bin/.launcher $out/bin/${pname}
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Ableton Live 12 Suite";
      genericName = "Music Production Software";
      categories = [ "Audio" "Midi" "Sequencer" "Music" "AudioVideo" ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = "ableton";
    src = ./ableton-256.png;
  };

  meta = with lib; {
    description = "Well-known music production software.";
    homepage = "https://www.ableton.com/en/products/live";
    platforms = [ "x86_64-linux" ];
  };
}
