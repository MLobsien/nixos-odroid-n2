{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-odroid-n2 = {
      url = "github:MLobsien/nixos-odroid-n2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixos-odroid-n2,
    ...
  }: let
    inherit (nixpkgs) lib;

    # Native x86_64 pkgs — for the sd-image builder (mkfs.ext4, sfdisk, etc.)
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowBroken = true;
    };

    # Cross aarch64 pkgs — cross-compiled on x86_64 for aarch64 Odroid N2.
    # crossSystem sets target to aarch64-linux while building natively on x86_64.
    crossPkgs = import nixpkgs {
      system = "x86_64-linux";
      crossSystem = "aarch64-linux";
      config.allowBroken = true;
    };

    minimalModule = {
      imports = [
        nixos-odroid-n2.nixosModules.default
      ];

      boot.loader.u-boot.enable = true;

      fileSystems."/" = lib.mkForce {
        device = "/dev/mmcblk0p2";
        fsType = "ext4";
      };

      system.stateVersion = "24.11";

      users.users.users = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        password = "11.42";
      };
    };

    targetSystem = lib.nixosSystem {
      pkgs = crossPkgs;
      modules = [
        minimalModule
      ];
    };

    sdImageSystem = lib.nixosSystem {
      inherit pkgs;
      specialArgs = {inherit targetSystem;};
      modules = [
        minimalModule
      ];
    };
  in {
    packages.x86_64-linux.default = sdImageSystem.config.system.build.sdImage;

    nixosConfigurations.default = targetSystem;
  };
}
