{
  description = "NixOS on Odroid N2";

  outputs = _: {
    nixosModules.default = import ./.;
  };
}
