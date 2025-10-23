{
  description = "NixOS configuration flake to install Ableton Live 12 Suite via Wine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/9f7b59b2758aa5913232ef797effe43d3384ca68";   # pinned
    erosanix.url = "github:emmanuelrosa/erosanix/72fc398838446ac66d67639e22c401137aa43d9e";
    flake-compat.url = "github:edolstra/flake-compat/35bb57c0c8d8b62bbfd284272c928ceb64ddbde9";
  };

  outputs = { self, nixpkgs, erosanix, flake-compat, ... }:
    let
      systems = [ "x86_64-linux" ];
    in
    {
      nixosConfigurations = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
          lib = pkgs.lib;
        in {
          name = "nixos-${system}";
          modules = [
            ./configuration.nix
            ({
              config, pkgs, ... }: {
                environment.systemPackages = with pkgs; [
                  wine
                  winetricks
                ];

                nixpkgs.config.allowUnfree = true;

                environment.systemPackages = lib.mkForce (
                  pkgs.callPackage (erosanix.pkgs.mkwindowsapp) {
                    pname = "ableton-live-12-suite";
                    version = "12";
                    src = ./path/to/AbletonLive12SuiteInstaller.zip;
                    winePrefix = "${config.home.homeDirectory}/.wine/ableton12";
                    installScript = ''
                      d="$WINEPREFIX/drive_c/${pname}_install"
                      mkdir -p "$d"
                      unzip ${src} -d "$d"
                      winetricks -q corefonts vcrun2019 gdiplus
                      wine "$d/Ableton Live 12 Suite Installer.exe"
                      rm -rf "$d"
                    '';
                  }
                );

                services.pipewire.enable = true;
                services.pipewire.alsa.enable = true;
                services.pipewire.pulse.enable = true;
                hardware.pulseaudio.enable = false;
                sound.enable = true;
                hardware.jack.enable = true;

                users.users.yourUser.extraGroups = [ "audio" ];
              }
            })
          ];
        }
      ) systems);
    };
}
