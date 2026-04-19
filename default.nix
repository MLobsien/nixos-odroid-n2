{
  modulesPath,
  # targetSystem,
  pkgs,
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
    loader.grub.enable = false;
    # kernelPackages = targetSystem.pkgs.linuxPackages_latest;
    # kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "console=ttyAML0,115200n8"
      "fsck.fix=yes"
      "fsck.repair=yes"
      "hdmitx=cec3f"
    ];
  };
}
