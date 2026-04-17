{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    # Native x86_64 pkgs — for the sd-image builder (mkfs.ext4, sfdisk, etc.)
    pkgs = import nixpkgs {system = "x86_64-linux";};

    # U-Boot (cross-compiled) and signed FIP.
    u-boot = import ./packages/u-boot.nix {inherit pkgs;};
    fip = import ./packages/fip.nix {
      inherit pkgs u-boot;
    };
  in {
    packages.x86_64-linux = {
      inherit u-boot fip;
      default = fip;
    };

    nixosModules.default.imports = [
      ./.
      (import ./u-boot.nix {inherit fip;})
    ];
  };
}
