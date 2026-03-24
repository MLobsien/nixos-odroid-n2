{
  config,
  pkgs,
  lib,
  stdenv,
  ...
}: let
  uboot-unwrapped = pkgs.pkgsCross.aarch64-multiplatform.buildUBoot {
    version = "v2026-03-17";
    src = pkgs.fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "33756fd4a8157d1d921a703c4fa172f6d2eadbd2";
      sha256 = "sha256-eLZzodCDL+6Vg8/ncqjf54Tk5MIG6mz+u0Lo84eLX9k=";
    };
    defconfig = "odroid-n2_defconfig";
    meta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };
  uboot-fip = stdenv.mkDerivation {
    pname = "amlogic-fip-tools";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "LibreELEC";
      repo = "amlogic-boot-fip";
      rev = "master";
      sha256 = "sha256-jKBym2QYeWpjFEHOSYprqG59zO/jZ7zUjfKWekf1MYw=";
    };

    nativeBuildInputs = with pkgs; [
      python3
      gnumake
      coreutils
      mktemp
    ];

    buildPhase = ''
      mkdir -p $out/bin
      patchShebangs ./odroid-n2
      ./build-fip.sh odroid-n2 ${uboot-unwrapped}/u-boot.bin $out/bin
    '';
  };
in {
  options.boot.loader.u-boot.enable = lib.mkEnableOption "U-Boot. This is only relevant for generating a sd image.";

  config = lib.mkIf config.boot.loader.u-boot.enable {
    boot.loader.generic-extlinux-compatible = true;

    sdImage = {
      populateFirmwareCommands = ''
        dd if=${uboot-fip}/bin/u-boot.bin.sd.bin of=$img bs=512 seek=1
      '';
      populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} \
          -d ./files/boot
      '';
    };
  };
}
