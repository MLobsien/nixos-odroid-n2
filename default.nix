{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
    ./kboot-conf.nix
  ];

  boot.loader.grub.enable = lib.mkForce false;
  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = lib.mkDefault [
    "console=ttyAML0,115200n8"
    "fsck.fix=yes"
    "fsck.repair=yes"
    "hdmitx=cec3f"
  ];

  hardware.deviceTree.name = lib.mkDefault "amlogic/meson-g12b-odroid-n2.dtb";
}
