{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs) stdenv fetchFromGitHub;

  # ----------------------------------------------------------------------
  # meson64-tools — open-source signing tools (for native on-device builds).
  # ----------------------------------------------------------------------
  meson64-tools = stdenv.mkDerivation {
    name = "meson64-tools";
    src = fetchFromGitHub {
      owner = "angerman";
      repo = "meson64-tools";
      rev = "b09cefd1e001dbba14036857bf6e167bf1833f26";
      sha256 = "/koIsslDNpaFHf1TV/0Xt0TiyhjL6tCz2oHQraYNhPA=";
    };
    nativeBuildInputs = with pkgs; [lz4 mbedtls];
    patches = [./api.patch ./make.patch];
    preBuild = ''
      rm -rf mbedtls/* lz4/*
      cp -r ${pkgs.lz4.dev}/include lz4
      cp -r ${pkgs.mbedtls.src}/include mbedtls
      ln -s ${pkgs.lz4.lib}/lib lz4/lib
      ln -s ${pkgs.mbedtls}/lib mbedtls/lib
    '';
    makeFlags = ["PREFIX=$(out)/bin"];
  };

  # ----------------------------------------------------------------------
  # Pre-built Amlogic FIP tools from LibreELEC (x86_64 host builds only).
  # ----------------------------------------------------------------------
  fip-tools = stdenv.mkDerivation {
    name = "amlogic-fip-tools";
    src = fetchFromGitHub {
      owner = "LibreELEC";
      repo = "amlogic-boot-fip";
      rev = "master";
      sha256 = "sha256-jKBym2QYeWpjFEHOSYprqG59zO/jZ7zUjfKWekf1MYw=";
    };
    nativeBuildInputs = with pkgs; [gnumake coreutils];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/odroid-n2 $out
    '';
  };

  # ----------------------------------------------------------------------
  # U-Boot for Odroid N2. Runs natively on the host (x86_64 or aarch64).
  # ----------------------------------------------------------------------
  u-boot = pkgs.buildUBoot {
    version = "v2026-03-17";
    src = fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "33756fd4a8157d1d921a703c4fa172f6d2eadbd2";
      sha256 = "sha256-eLZzodCDL+6Vg8/ncqjf54Tk5MIG6mz+u0Lo84eLX9k=";
    };
    defconfig = "odroid-n2_defconfig";
    meta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };

  # ----------------------------------------------------------------------
  # FIP package — signs the Amlogic boot chain and assembles u-boot.bin.
  # ----------------------------------------------------------------------
  fip' = stdenv.mkDerivation {
    name = "fip";

    src = fip-tools;

    nativeBuildInputs = with pkgs; [u-boot lz4];

    buildPhase = ''
      fip=$src/odroid-n2
      outBin=$out/bin
      mkdir -p $outBin

      # blx_fix: pad bl30/bl2 to fixed sizes, concatenate with bl301/acs.

      # bl30_new.bin = bl30.bin (41K) + bl301.bin (12K)
      ${pkgs.coreutils}/bin/dd if=/dev/zero of=bl30_zero.bin  bs=1 count=40960 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=$fip/bl30.bin  of=bl30_zero.bin conv=notrunc 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=/dev/zero of=bl301_zero.bin bs=1 count=13312 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=$fip/bl301.bin of=bl301_zero.bin conv=notrunc 2>/dev/null
      cat bl30_zero.bin bl301_zero.bin > bl30_new.bin

      # bl2_new.bin = bl2.bin (57K) + acs.bin (4K)
      ${pkgs.coreutils}/bin/dd if=/dev/zero of=bl2_zero.bin  bs=1 count=57344 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=$fip/bl2.bin  of=bl2_zero.bin conv=notrunc 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=/dev/zero of=bl21_zero.bin bs=1 count=4096  2>/dev/null
      ${pkgs.coreutils}/bin/dd if=$fip/acs.bin  of=bl21_zero.bin conv=notrunc 2>/dev/null
      cat bl2_zero.bin bl21_zero.bin > bl2_new.bin

      # LZ4-compress U-Boot (BL33)
      cp $u-boot/bin/u-boot.bin ./bl33.bin
      lz4 -f -12 ./bl33.bin ./bl33.bin.lz4

      # Signing pipeline via aml_encrypt_g12b (x86_64 binary)
      AML_ENCRYPT=$fip/aml_encrypt_g12b

      $AML_ENCRYPT --bl2sig --input bl2_new.bin --output bl2.n.bin.sig
      $AML_ENCRYPT --bl30sig --input bl30_new.bin --output bl30_new.bin.g12a.enc --level v3
      $AML_ENCRYPT --bl3sig --input bl30_new.bin.g12a.enc --output bl30_new.bin.enc --level v3 --type bl30
      $AML_ENCRYPT --bl3sig --input $fip/bl31.img --output bl31.img.enc --level v3 --type bl31
      $AML_ENCRYPT --bl3sig --input bl33.bin.lz4 --output bl33.bin.enc --level v3 --type bl33 --compress lz4

      $AML_ENCRYPT --bootmk --output u-boot.bin --level v3 \
        --bl2 bl2.n.bin.sig \
        --bl30 bl30_new.bin.enc \
        --bl31 bl31.img.enc \
        --bl33 bl33.bin.enc \
        --ddrfw1 $fip/ddr4_1d.fw \
        --ddrfw2 $fip/ddr4_2d.fw \
        --ddrfw3 $fip/ddr3_1d.fw \
        --ddrfw4 $fip/piei.fw \
        --ddrfw5 $fip/lpddr4_1d.fw \
        --ddrfw6 $fip/lpddr4_2d.fw \
        --ddrfw7 $fip/diag_lpddr4.fw \
        --ddrfw8 $fip/aml_ddr.fw

      # SD-card variant: BL2 prepended to 512-byte sector boundary
      ${pkgs.coreutils}/bin/dd if=bl2.n.bin.sig of=u-boot.bin.sd.bin bs=512 count=1 2>/dev/null
      ${pkgs.coreutils}/bin/dd if=u-boot.bin    of=u-boot.bin.sd.bin bs=512 seek=1 conv=notrunc 2>/dev/null

      install -Dm755 u-boot.bin       $outBin/u-boot.bin
      install -Dm755 u-boot.bin.sd.bin $outBin/u-boot.bin.sd.bin
    '';

    installPhase = ''
      mkdir -p $out
    '';
  };
in {
  options.boot.loader.u-boot = {
    enable = lib.mkEnableOption "U-Boot bootloader (SD image) for Odroid N2";
    fip = lib.mkOption {
      type = lib.types.path;
      default = fip';
      description = "Path to the signed FIP package (u-boot.bin + u-boot.bin.sd.bin)";
    };
  };

  config = lib.mkIf config.boot.loader.u-boot.enable {
    boot.loader.generic-extlinux-compatible.enable = true;

    sdImage = {
      populateFirmwareCommands = ''
        dd if=${config.boot.loader.u-boot.fip}/u-boot.bin.sd.bin of=$img bs=512 seek=1
      '';
      populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} \
          -d ./files/boot
      '';
    };
  };
}
