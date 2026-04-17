{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    inherit (nixpkgs) lib;

    # Native x86_64 pkgs — for the sd-image builder (mkfs.ext4, sfdisk, etc.)
    pkgs = import nixpkgs {system = "x86_64-linux";};

    # Cross aarch64 pkgs — cross-compiled on x86_64 for aarch64 Odroid N2.
    # crossSystem sets target to aarch64-linux while building natively on x86_64.
    crossPkgs = import nixpkgs {
      system = "x86_64-linux";
      crossSystem = "aarch64-linux";
    };

    # U-Boot (cross-compiled) and signed FIP.
    u-boot = import ./packages/u-boot.nix {inherit pkgs;};
    fip = import ./packages/fip.nix {
      inherit pkgs u-boot;
    };

    minimalModule = {
      boot.loader.u-boot.enable = true;

      system.stateVersion = "24.11";
    };

    targetSystem = lib.nixosSystem {
      pkgs = crossPkgs;
      modules = [
        self.nixosModules.default
        {
          system.stateVersion = "24.11";
        }
        minimalModule
      ];
    };

    # -------------------------------------------------------------------------
    # SD-IMAGE SYSTEM — builds the SD image using native x86_64 tools.
    #
    # The problem: nixosSystem { system = "aarch64-linux" } makes the sd-image
    # derivation use aarch64 binaries for mkfs.ext4, sfdisk, mcopy → can't run
    # on the x86_64 build host.
    #
    # The fix: separate nixosSystem call with native pkgs.  It uses
    # targetSystem's aarch64 toplevel so boot files are correct architecture.
    # -------------------------------------------------------------------------
    sdImageSystem = lib.nixosSystem {
      inherit pkgs;
      specialArgs = {inherit targetSystem;};
      modules = [
        self.nixosModules.default
        minimalModule
      ];
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
