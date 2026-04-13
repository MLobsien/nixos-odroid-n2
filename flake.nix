{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    uboot = import ./packages/uboot.nix {inherit pkgs;};
    fip = import ./packages/fip.nix {inherit pkgs uboot;};
  in {
    nixosModules.default.imports = [
      ./.
      (import ./uboot.nix {inherit fip;})
    ];

    packages.x86_64-linux = {
      inherit uboot fip;
      default = fip;
    };
  };
}
