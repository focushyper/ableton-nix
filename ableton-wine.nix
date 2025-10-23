{ lib
, mkWindowsApp ? (import (fetchTarball "https://github.com/fufexan/winapps-nix/archive/master.tar.gz")).mkWindowsApp
, wine ? (import <nixpkgs> {}).wineWowPackages.full
, winetricks ? (import <nixpkgs> {}).winetricks
, fetchurl
, makeDesktopItem
, makeDesktopIcon
, copyDesktopItems
, copyDesktopIcons
, unzip
, makeWrapper
, wineasio ? null
}:

mkWindowsApp rec {
  inherit wine;

  pname   = "ableton";
  version = "12.2.6";

  src = fetchurl {
    url    = "https://cdn-downloads.ableton.com/channels/${version}/ableton_live_suite_${version}_64.zip";
    sha256 = "1hlfxg67zlcblvfy41yw3m5v518fv1a8v2ghf2wf7xy5iysxp8j7";
  };

  dontUnpack = true;
  wineArch   = "win64";
  persistRegistry       = true;
  persistRuntimeLayer   = true;
  fileMapDuringAppInstall = true;

  fileMap = {
    "home/.config/Ableton" = "drive_c/users/$USER/AppData/Roaming/Ableton";
  };

  buildInputs = [ copyDesktopItems copyDesktopIcons unzip winetricks ]
    ++ lib.optionals (wineasio != null) [ wineasio ];

  winAppInstall = ''
    set -eu
    d="$WINEPREFIX/drive_c/${pname}_install"
    PATH="${lib.makeBinPath [ unzip winetricks ]}:$PATH"

    mkdir -p "$d"
    unzip -q ${src} -d "$d"

    "${winetricks}/bin/winetricks" -q settings win10 fontsmooth=rgb csmt=on
    "${winetricks}/bin/winetricks" -q corefonts tahoma vcrun2019 gdiplus msxml6
    "${winetricks}/bin/winetricks" -q --force dotnet48

    ${lib.optionalString (wineasio != null) ''
      regsvr32 wineasio.dll || true
    ''}

    exe="$(find "$d" -maxdepth 2 -type f -name 'Ableton*Installer*.exe' -o -name 'Ableton Live * Suite Installer*.exe' | head -n1)"
    if [ -z "$exe" ]; then
      echo "Ableton installer .exe not found in $d" >&2
      exit 1
    fi
    wine "$exe"
    rm -rf "$d"
  '';

  winAppRun = ''
    export WINEESYNC=1
    export WINEFSYNC=1
    export PULSE_LATENCY_MSEC=60
    wine "$WINEPREFIX/drive_c/ProgramData/Ableton/Live 12 Suite/Program/Ableton Live 12 Suite.exe"
  '';

  installPhase = ''
    runHook preInstall
    ln -s "$out/bin/.launcher" "$out/bin/${pname}"
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
    description = "Ableton Live 12 Suite via Wine";
    homepage    = "https://www.ableton.com/en/products/live";
    platforms   = [ "x86_64-linux" ];
    maintainers = with maintainers; [ ];
  };
}
