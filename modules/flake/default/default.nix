# SPDX-License-Identifier: MIT
#
# The exported flake module, for consumers composing this flake with
# caisson. Consuming the drivers needs none of it: `overlays.packages`
# is a plain nixpkgs overlay and `packages.<system>` holds every build,
# so any flake can take either without adopting a framework.
{ mkModule, ... }:
{ ... }:
{
  imports = [
    (mkModule ./edk2-platforms-nix)
  ];
}
