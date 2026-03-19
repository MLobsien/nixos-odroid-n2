{
  pkgs,
  lib,
  modulesPath,
  ...
}: let
  system = "aarch64-linux";
in {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/cd-dvd/sd-image.nix")
    ./kboot-conf
  ];

  nixpkgs = {
    overlays = [(import ./packages)];
    crossSystem =
      lib.mkIf (
        pkgs.stdenv.hostPlatform.system != system
      )
      {inherit system;};
  };

  boot.loader.grub.enable = false;
  boot.consoleLogLevel = 7;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "console=ttyAML0,115200n8"
    "no_console_suspend"
    "consoleblank=0"
    "fsck.fix=yes"
    "fsck.repair=yes"
    "net.ifnames=0"
    "elevator=noop"
    "enable_wol=1"
    "usb-xhci.tablesize=2"
    "maxcpus=6"
    "hdmitx=cec3f"
  ];

  hardware.deviceTree.name = "amlogic/meson-g12b-odroid-n2-plus.dtb";
}
