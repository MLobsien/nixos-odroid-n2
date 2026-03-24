{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
    ./kboot-conf.nix
    ./uboot.nix
  ];

  boot.loader.grub.enable = false;
  boot.consoleLogLevel = 7;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "console=ttyAML0,115200n8"
    "fsck.fix=yes"
    "fsck.repair=yes"
    "hdmitx=cec3f"
  ];

  hardware.deviceTree.name = "amlogic/meson-g12b-odroid-n2.dtb";
}
