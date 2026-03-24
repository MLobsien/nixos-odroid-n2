{
  description = "NixOS on Odroid N2";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.11-small";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    packages = {
      default = pkgs.callPackage ./packages/fip.nix {inherit (self.packages) uboot;};
      uboot = pkgs.callPackage ./packages/uboot.nix {};
    };
    nixosModules.default = import ./.;
  };
}
