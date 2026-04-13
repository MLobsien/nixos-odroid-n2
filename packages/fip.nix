{
  pkgs,
  uboot,
  ...
}: let
  inherit (pkgs) stdenv fetchFromGitHub lz4 coreutils;
in
  stdenv.mkDerivation {
    name = "fip";

    src = fetchFromGitHub {
      owner = "LibreELEC";
      repo = "amlogic-boot-fip";
      rev = "master";
      sha256 = "sha256-jKBym2QYeWpjFEHOSYprqG59zO/jZ7zUjfKWekf1MYw=";
    };

    nativeBuildInputs = [uboot lz4 coreutils];

    buildPhase = ''
      fip=$src/odroid-n2
      outBin=$out/bin
      mkdir -p $outBin

      ${coreutils}/bin/dd if=/dev/zero of=bl30_zero.bin  bs=1 count=40960 2>/dev/null
      ${coreutils}/bin/dd if=$fip/bl30.bin  of=bl30_zero.bin conv=notrunc 2>/dev/null
      ${coreutils}/bin/dd if=/dev/zero of=bl301_zero.bin bs=1 count=13312 2>/dev/null
      ${coreutils}/bin/dd if=$fip/bl301.bin of=bl301_zero.bin conv=notrunc 2>/dev/null
      cat bl30_zero.bin bl301_zero.bin > bl30_new.bin

      ${coreutils}/bin/dd if=/dev/zero of=bl2_zero.bin  bs=1 count=57344 2>/dev/null
      ${coreutils}/bin/dd if=$fip/bl2.bin  of=bl2_zero.bin conv=notrunc 2>/dev/null
      ${coreutils}/bin/dd if=/dev/zero of=bl21_zero.bin bs=1 count=4096  2>/dev/null
      ${coreutils}/bin/dd if=$fip/acs.bin  of=bl21_zero.bin conv=notrunc 2>/dev/null
      cat bl2_zero.bin bl21_zero.bin > bl2_new.bin

      cp ${uboot}/u-boot.bin ./bl33.bin
      lz4 -f -12 ./bl33.bin ./bl33.bin.lz4

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

      ${coreutils}/bin/dd if=bl2.n.bin.sig of=u-boot.bin.sd.bin bs=512 count=1 2>/dev/null
      ${coreutils}/bin/dd if=u-boot.bin    of=u-boot.bin.sd.bin bs=512 seek=1 conv=notrunc 2>/dev/null

      install -Dm755 u-boot.bin       $outBin/u-boot.bin
      install -Dm755 u-boot.bin.sd.bin $outBin/u-boot.bin.sd.bin
    '';

    installPhase = ''
      mkdir -p $out
    '';
  }
