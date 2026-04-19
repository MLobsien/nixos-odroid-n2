{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};

    # U-Boot (cross-compiled) and signed FIP.
    u-boot = import ./packages/u-boot.nix {inherit pkgs;};
    fip = import ./packages/fip.nix {
      inherit pkgs u-boot;
    };

    inherit (nixpkgs) lib;

    # Cross aarch64 pkgs — cross-compiled on x86_64 for aarch64 Odroid N2.
    # crossSystem sets target to aarch64-linux while building natively on x86_64.
    crossPkgs = import nixpkgs {
      system = "x86_64-linux";
      crossSystem = "aarch64-linux";
      config.allowBroken = true;
    };

    minimalModule = {
      imports = [
        self.nixosModules.default
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
    packages.x86_64-linux = {
      inherit u-boot fip;
      # default = fip;
    };
    nixosConfigurations.default = targetSystem;

    nixosModules.default.imports = [
      ./.
      (import ./u-boot.nix {inherit fip;})
    ];
  };
}
