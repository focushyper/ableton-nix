{ lib
, mkWindowsApp
, wine
, winetricks
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

  # If your mkWindowsApp supports these, keep them; otherwise remove.
  persistRegistry       = true;
  persistRuntimeLayer   = true;
  fileMapDuringAppInstall = true;
  inputHashMethod       = "store-path";

  # Safer LHS; RHS usually resolves correctly under Wine
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

    # Baseline settings
    "${winetricks}/bin/winetricks" -q settings win10 fontsmooth=rgb csmt=on

    # Runtimes
    "${winetricks}/bin/winetricks" -q corefonts tahoma vcrun2019 gdiplus msxml6
    # .NET 4.8 often needs --force to finish silently
    "${winetricks}/bin/winetricks" -q --force dotnet48

    # Register wineasio if available (ignore if fails)
    ${lib.optionalString (wineasio != null) ''
      regsvr32 wineasio.dll || true
    ''}

    # Ableton installer (sometimes folder nesting occurs after unzip)
    exe="$(find "$d" -maxdepth 2 -type f -name 'Ableton*Installer*.exe' -o -name 'Ableton Live * Suite Installer*.exe' | head -n1)"
    if [ -z "$exe" ]; then
      echo "Ableton installer .exe not found in $d" >&2
      exit 1
    fi
    wine "$exe"

    rm -rf "$d"
  '';

  winAppPreRun = '''';

  winAppRun = ''
    export WINEESYNC=1
    export WINEFSYNC=1
    export PULSE_LATENCY_MSEC=60
    wine "$WINEPREFIX/drive_c/ProgramData/Ableton/Live 12 Suite/Program/Ableton Live 12 Suite.exe"
  '';

  winAppPostRun = '''';

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
  };
}
