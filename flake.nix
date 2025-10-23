{
  description = "Ableton Live 12 Suite on NixOS via Wine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        wineAbleton = pkgs.callPackage ./ableton-wine.nix { };

      in {
        packages.default = wineAbleton;

        # optional devShell: good for testing your prefix
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            wineWowPackages.full
            winetricks
            unzip
            p7zip
            alsa-lib
            pipewire
            jack2
            fontconfig
            corefonts
          ];

          shellHook = ''
            echo ">>> Ableton Wine Shell Ready"
            echo "Run: winecfg  (then run your ableton-wine app)"
          '';
        };
      }
    );
}
