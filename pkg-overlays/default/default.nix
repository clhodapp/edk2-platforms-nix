# SPDX-License-Identifier: MIT
#
# The default package overlay: this flake's packages under
# `pkgs.edk2-platforms-nix`, built from the sources this flake pins. A
# consumer that lists this flake in `projects` holds it as
# `edk2-platforms-nix/default`, which its package sets apply by default.
# The scope name is bound here, so the packages land under
# `pkgs.edk2-platforms-nix` in any consumer.
#
# The package tree stays at pkgs/edk2-platforms-nix: the release
# workflow writes its version.nix, and the lib overlay and extras.nix
# read it too.
{ closure-inputs, closure-lib, ... }:
let
  edk2Lib = closure-lib.edk2-platforms-nix;
in
{
  overlay = closure-lib.caisson.nixpkgs.mkPackagesOverlay (
    { callPackage, lib, ... }:
    import ../../pkgs/edk2-platforms-nix {
      inherit callPackage lib edk2Lib;
      inherit (closure-inputs) edk2-src edk2-unstable-src edk2-platforms;
    }
  ) "edk2-platforms-nix";
}
