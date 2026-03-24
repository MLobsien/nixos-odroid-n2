{
  description = "NixOS on Odroid N2";

  outputs = {...}: {
    nixosModules.default = import ./.;
  };
}
