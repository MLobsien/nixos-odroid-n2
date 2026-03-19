{
  stdenv,
  uboot,
  pkgs,
  ...
}:
stdenv.mkDerivation {
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
    ./build-fip.sh odroid-n2 ${uboot}/u-boot.bin $out/bin
  '';
}
