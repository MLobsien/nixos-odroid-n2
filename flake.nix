{
  description = "NixOS on Odroid N2";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11-small";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    (flake-utils.lib.eachSystem ["aarch64-linux" "x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        crossSytem.config = "aarch64-unknown-linux-gnu";
      };
    in {
      packages = {
        default = pkgs.callPackage ./packages/fip.nix {
          uboot = pkgs.callPackage ./packages/uboot.nix {inherit pkgs;};
        };
      };
    }))
    // {
      nixosModules.default = import ./.;
    };
}
