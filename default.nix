{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/system/boot/loader/generic-extlinux-compatible")
    (modulesPath + "/installer/sd-card/sd-image.nix")
    ./kboot-conf.nix
  ];

  boot = {
    consoleLogLevel = lib.mkDefault 7;
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    loader.grub.enable = false;
  };

  # Let the device tree be auto-detected or pass via kernel params.
  # Note: cross-compiled kernel needs FDTDIR in the boot partition,
  # which isn't available in the sd-image without extra configuration.
  # Instead, pass the dtb via kernel params in boot.kernelParams.
  boot.kernelParams = lib.mkDefault [
    "console=ttyAML0,115200n8"
    "fsck.fix=yes"
    "fsck.repair=yes"
    "hdmitx=cec3f"
  ];
}
