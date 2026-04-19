{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-odroid-n2 = {
      # url = "github:MLobsien/nixos-odroid-n2";
      url = "path:..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixos-odroid-n2,
    ...
  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowBroken = true;
    };
    inherit (pkgs) lib;
  in {
    nixosConfigurations.default = lib.nixosSystem {
      pkgs = pkgs.pkgsCross.aarch64-multiplatform;
      modules = [
        ({pkgs, ...}: {
          imports = [
            nixos-odroid-n2.nixosModules.default
          ];

          environment.systemPackages = [pkgs.vim];

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
        })
      ];
    };
  };
}
