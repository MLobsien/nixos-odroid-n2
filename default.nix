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
  ];

  boot.loader.grub.enable = false;
  boot.consoleLogLevel = 7;
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

  # Is this necessary?
  # sdImage.populateFirmwareCommands = let
  #   configTxt = pkgs.writeText "README" ''
  #     Nothing to see here. This empty partition is here because I don't know how to turn its creation off.
  #   '';
  # in ''
  #   cp ${configTxt} firmware/README
  # '';
}
