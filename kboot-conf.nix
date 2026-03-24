{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.boot.loader.kboot-conf;
  mkBuilder = p: ''
    shopt -s nullglob

    PATH=${p.lib.makeBinPath (with p; [coreutils gnused gnugrep])}

    target=/kboot.conf
    default=""

    while getopts "c:d:" opt; do
        case "$opt" in
            c) default="$OPTARG" ;;
            d) target="$OPTARG" ;;
        esac
    done

    tmp=$target.tmp

    addEntry() {
        local path=$(readlink -f "$1")
        local tag="$2"

        if ! test -e $path/kernel -a -e $path/initrd; then
            return
        fi

        timestampEpoch=$(stat -L -c '%Z' $path)
        timestamp=$(date "+%Y-%m-%d %H:%M" -d @$timestampEpoch)
        nixosLabel="$(cat $path/nixos-version)"
        extraParams="$(cat $path/kernel-params)"

        local kernel=$(readlink -f "$path/kernel")
        local initrd=$(readlink -f "$path/initrd")
        local dtbs=$(readlink -f "$path/dtbs")

        local id="nixos-$tag--$nixosLabel"

        if [ "$tag" = "default" ]; then
            echo "default=$id"
        fi

        echo -n "$id='"
        echo -n "$kernel initrd=$initrd dtb=$dtbs/${config.hardware.deviceTree.name} "
        echo -n "systemConfig=$path init=$path/init $extraParams"
        echo "'"
    }

    addEntry $default default >> $tmp

    if [ ${toString cfg.configurationLimit} -gt 0 ]; then
        for generation in $(
                ls -d /nix/var/nix/profiles/system-*-link \
                | sed 's/system-\([0-9]\+\)-link/\1/' \
                | head -n ${toString cfg.configurationLimit}); do
            link=/nix/var/nix/profiles/system-$(basename $generation)-link
            addEntry $link $generation
        done >> $tmp
    fi

    mv -f $tmp $target
  '';
in {
  options.boot.loader.kboot-conf = {
    enable = lib.mkEnableOption "creating petitboot-compatible /kboot.conf";
    configurationLimit = lib.mkOption {
      default = 10;
      example = 5;
      type = lib.types.int;
      description = ''
        Maximum number of configurations in the generated kboot.conf.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    system = {
      build.installBootLoader = mkBuilder pkgs;
      boot.loader.id = "kboot-conf";
    };

    sdImage = {
      populateRootCommands = ''
        ${mkBuilder pkgs.buildPackages} -c ${config.system.build.toplevel} -d ./files/kboot.conf
      '';

      populateFirmwareCommands = lib.mkOverride 0 "";
    };
  };
}
