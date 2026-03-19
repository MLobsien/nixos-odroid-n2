{
  description = "NixOS on Odroid N2";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.11-small";

  outputs = {nixpkgs, ...}: let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    packages.default = pkgs.callPackage ./packages/fip.nix {
      uboot = pkgs.callPackage ./packages/uboot.nix {inherit pkgs;};
    };
    nixosModules.default = import ./.;
  };
}
