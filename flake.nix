# SPDX-FileCopyrightText: 2024 Caleb Depatie
# SPDX-FileCopyrightText: 2024 Conner Tenn
#
# SPDX-License-Identifier: 0BSD

# The flake allows locking dependencies. Given our use of the relatively quick changing
# Zig, having more control over when we upgrade is useful
{
  description = "A library for making it easier to using zig with the Pi Pico.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem 
    (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Built via `nix build` and run via `nix run`
        # Building as a package not required

        # Entered with `nix develop`
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zig
            git
            cmake
            gcc-arm-embedded-13
          ];
        };
      }
    );
}
