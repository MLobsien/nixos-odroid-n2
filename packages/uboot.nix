{pkgs, ...}:
pkgs.pkgsCross.aarch64-multiplatform.buildUBoot {
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
}
