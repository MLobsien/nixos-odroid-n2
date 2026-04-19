{fip}: {
  config,
  lib,
  # targetSystem,
  ...
}: {
  options.boot.loader.u-boot.enable = lib.mkEnableOption "U-Boot bootloader (SD image) for Odroid N2";

  config = lib.mkIf config.boot.loader.u-boot.enable {
    boot.loader.generic-extlinux-compatible = {
      enable = true;
      configurationLimit = 0;
    };

    sdImage = {
      populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} \
          -d ./files/boot
      '';

      populateFirmwareCommands = "";

      # Write the signed FIP directly to the MBR/pre-partition area.
      # Sector 0 = MBR, sector 1-2047 = MBR gap (where Amlogic boot ROM
      # reads bl2 from), sector 2048+ = root partition.
      # The FAT /boot/firmware partition is not used on Amlogic — we erase
      # its entry from the MBR partition table below.
      postBuildCommands = ''
        dd if=${fip}/bin/u-boot.bin.sd.bin of=$img bs=512 seek=1 conv=notrunc

        # Zero out the FAT partition entry (type 0x0B) so it is invisible
        # to host tools and does not confuse the Amlogic boot ROM.
        # MBR layout:
        #   0x000–0x1BD  Bootstrap code (446 bytes)
        #   0x1BE–0x1CD  Partition entry 0 = FAT (type at 0x1BE+4 = 0x1C2)
        #   0x1CE–0x1DD  Partition entry 1 = root (type at 0x1CE+4 = 0x1D2)
        #   0x1DE–0x1ED  Partition entry 2
        #   0x1EE–0x1FD  Partition entry 3
        #   0x1FE–0x1FF  Boot signature 0x55AA
        printf '\x00' | dd of=$img bs=1 count=1 seek=450 conv=notrunc
      '';
    };
  };
}
