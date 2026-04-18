{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
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
