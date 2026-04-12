{
  description = "NixOS on Odroid N2 (Amlogic S922X)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:

    let
      # Default nixpkgs for packages (x86_64-linux).
      pkgs = import nixpkgs { system = "x86_64-linux"; };

    in {

    # ------------------------------------------------------------------
    # NixOS module — minimal config for Odroid N2.
    # Import this in your own NixOS configuration:
    #
    #   imports = [ github:user/nixos-odroid-n2 ];
    #
    # The module sets up U-Boot, extlinux boot, device-tree, and kernel.
    # ------------------------------------------------------------------
    nixosModules.default = { pkgs, lib, modulesPath, ... }: {
      imports = [
        (modulesPath + "/profiles/base.nix")
        (modulesPath + "/profiles/installation-device.nix")
        (modulesPath + "/installer/sd-card/sd-image.nix")
        ./default.nix
        ./kboot-conf.nix
        ./uboot/default.nix
      ];

      boot.loader.grub.enable = lib.mkForce false;
      boot.consoleLogLevel   = lib.mkDefault 7;
      boot.kernelPackages     = lib.mkDefault pkgs.linuxPackages_latest;
      boot.kernelParams       = lib.mkDefault [
        "console=ttyAML0,115200n8"
        "fsck.fix=yes"
        "fsck.repair=yes"
        "hdmitx=cec3f"
      ];

      hardware.deviceTree.name = lib.mkDefault "amlogic/meson-g12b-odroid-n2.dtb";
    };

    # ------------------------------------------------------------------
    # Packages — all built natively on x86_64 (the build machine).
    # ------------------------------------------------------------------
    packages.x86_64-linux = {
      fip       = import ./packages/fip  { inherit pkgs; };
      uboot     = import ./packages/uboot { inherit pkgs; };
      default   = self.packages.x86_64-linux.fip;
    };

  };
}
