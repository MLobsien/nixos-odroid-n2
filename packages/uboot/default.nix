{ pkgs ? (
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { system = "x86_64-linux"; }
  )
}:
with pkgs;
stdenv.mkDerivation {
  name = "u-boot-odroid-n2";

  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "33756fd4a8157d1d921a703c4fa172f6d2eadbd2";
    sha256 = "sha256-eLZzodCDL+6Vg8/ncqjf54Tk5MIG6mz+u0Lo84eLX9k=";
  };

  nativeBuildInputs = [ python3 python3Packages.pyelftools ];

  makeFlags = [
    "CROSS_COMPILE=aarch64-unknown-linux-gnu-"
    "defconfig=odroid-n2_defconfig"
  ];

  # buildUBoot defaults to aarch64-linux; we run on x86_64, so allow the host.
  meta.platforms = ["aarch64-linux" "x86_64-linux"];

  installPhase = ''
    install -Dm644 u-boot.bin $out/u-boot.bin
    install -Dm644 .config $out/.config
  '';
}
