{pkgs, ...}:
# Build U-Boot for Odroid N2 (Amlogic S922X / ARM64) on x86_64.
#
# We bypass pkgs.buildUBoot because it uses aarch64-linux-gnu-* as the
# target triple, but nixpkgs provides aarch64-unknown-linux-gnu-* instead.
# Here we resolve the correct cross-compiler path via pkgsCross.
let
  inherit (pkgs) stdenv fetchFromGitHub;

  # Resolve the cross-compiler for aarch64. nixpkgs uses the "unknown" sysroot,
  # not the "linux" sysroot, so the triple is aarch64-unknown-linux-gnu-*.
  aarch64Stdenv = pkgs.pkgsCross.aarch64-multiplatform.stdenv;
  ccBin = "${aarch64Stdenv.cc}/bin";
  # Native gcc for host tools (fixdep, conf, dtc, etc.)
  hostCc = "${pkgs.gcc}/bin/gcc";
in
  stdenv.mkDerivation {
    name = "uboot-odroid-n2";
    version = "v2026-03-17";

    src = fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "33756fd4a8157d1d921a703c4fa172f6d2eadbd2";
      sha256 = "sha256-eLZzodCDL+6Vg8/ncqjf54Tk5MIG6mz+u0Lo84eLX9k=";
    };

    nativeBuildInputs = with pkgs; [
      bash
      bc
      bison
      dtc
      flex
      gnutls.dev
      openssl.dev
      pkg-config
      (python3.withPackages (p: [p.libfdt p.pyelftools p.setuptools]))
    ];

    postPatch = ''
      patchShebangs --build tools scripts
    '';

    buildPhase = ''
      export ARCH=arm64
      export CROSS_COMPILE=${ccBin}/aarch64-unknown-linux-gnu-
      export HOSTCC=${hostCc}
      export DTC=${pkgs.dtc}/bin/dtc

      make odroid-n2_defconfig
      make -j''${NIX_BUILD_CORES:-$(nproc)}
    '';

    installPhase = ''
      mkdir -p $out
      cp u-boot.bin $out/u-boot.bin
      cp .config    $out/.config
    '';
  }
