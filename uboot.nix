{
  config,
  pkgs,
  lib,
  ...
}: let
  fip = pkgs.stdenv.mkDerivation {
    name = "fip";

    MESON64-TOOLS = pkgs.stdenv.mkDerivation {
      name = "meson64-tools";
      src = pkgs.fetchFromGitHub {
        owner = "angerman";
        repo = "meson64-tools";
        rev = "b09cefd1e001dbba14036857bf6e167bf1833f26";
        sha256 = "/koIsslDNpaFHf1TV/0Xt0TiyhjL6tCz2oHQraYNhPA=";
      };

      nativeBuildInputs = [pkgs.python2 pkgs.python3];

      preBuild = ''
        patchShebangs .
        patchShebangs ./mbedtls/scripts/generate_psa_constants.py
      '';

      makeFlags = ["PREFIX=$(out)/bin"];
    };

    FIP_TOOLS = pkgs.stdenv.mkDerivation {
      pname = "amlogic-fip-tools";
      version = "unstable";

      src = pkgs.fetchFromGitHub {
        owner = "LibreELEC";
        repo = "amlogic-boot-fip";
        rev = "master";
        sha256 = "sha256-jKBym2QYeWpjFEHOSYprqG59zO/jZ7zUjfKWekf1MYw=";
      };

      nativeBuildInputs = with pkgs; [
        gnumake
        coreutils
        mktemp
      ];
    };

    UBOOT = pkgs.buildUBoot {
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

    buildPhase = ''
      mkdir -p $TMPDIR/tools
      ln -s $MESON64_TOOLS/
    '';
  };
in {
  options.boot.loader.u-boot.enable = lib.mkEnableOption "U-Boot. This is only relevant for generating a sd image.";

  config = lib.mkIf config.boot.loader.u-boot.enable {
    boot.loader.generic-extlinux-compatible.enable = true;

    sdImage = {
      populateFirmwareCommands = ''
        dd if=${fip}/bin/u-boot.bin.sd.bin of=$img bs=512 seek=1
      '';
      populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} \
          -d ./files/boot
      '';
    };
  };
}
