# SPDX-License-Identifier: MIT
#
# The exported flake module, for consumers composing this flake with
# caisson. Consuming the driver needs none of it: `overlays.packages`
# is a plain nixpkgs overlay and `packages.<system>` holds both
# architectures' builds, so any flake can take either without adopting
# a framework.
{ mkModule, ... }:
{ ... }:
{
  imports = [
    (mkModule ./ext4-dxe)
  ];
}
