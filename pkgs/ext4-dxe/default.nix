# SPDX-License-Identifier: MIT
{
  lib,
  callPackage,
  edk2-src,
  edk2-unstable-src,
  edk2-platforms,
  ...
}:
let
  version = import ./ext4-dxe/version.nix;

  # nixpkgs' edk2 package (the BaseTools build and the source tree that
  # edk2.mkDerivation compiles in) over a given edk2 tree, as an overlay
  # on the whole package set: edk2.mkDerivation takes BaseTools from
  # buildPackages.edk2, and the AArch64 driver is built from pkgsCross,
  # so a per-package override would leave those at nixpkgs' own edk2.
  #
  # The tree is used as shipped, submodules included. nixpkgs' recipe
  # patches its own tree for the GCC5 toolchain (reading the prefix
  # from the environment) and de-vendors OpenSSL; from edk2-stable202608
  # GCC5 is gone and the GCC toolchain reads its prefix from the
  # environment already (see ./ext4-dxe), and nothing built here uses
  # CryptoPkg.
  withEdk2 =
    { src, edk2Version }:
    pkgs:
    pkgs.extend (
      final: prev: {
        edk2 = prev.edk2.overrideAttrs (_: {
          version = edk2Version;
          srcWithVendoring = src;
          inherit src;
        });
      }
    );

  stable = {
    src = edk2-src;
    edk2Version = version.edk2;
    driverVersion = "${version.edk2}.${toString version.revision}";
  };
  unstable = rec {
    src = edk2-unstable-src;
    edk2Version = "0-unstable-${lib.substring 0 8 edk2-unstable-src.lastModifiedDate}";
    driverVersion = edk2Version;
  };

  # The driver is architecture-neutral C and edk2 selects the target
  # from the host platform, so the AArch64 package set's callPackage is
  # the whole difference; it is built from x86-64 (the CI runner) with
  # nixpkgs' cross toolchain.
  mkDriver =
    core: aarch64:
    callPackage (
      { pkgs }:
      let
        pkgsWithEdk2 = withEdk2 { inherit (core) src edk2Version; } pkgs;
        pkgsForTarget = if aarch64 then pkgsWithEdk2.pkgsCross.aarch64-multiplatform else pkgsWithEdk2;
      in
      pkgsForTarget.callPackage ./ext4-dxe {
        inherit edk2-platforms;
        version = core.driverVersion;
      }
    ) { };
in
{
  # The released driver: against the edk2 stable tag in version.nix.
  ext4-dxe = mkDriver stable false;
  ext4-dxe-aarch64 = mkDriver stable true;

  # Against edk2 master as last advanced; built and checked, never
  # released.
  ext4-dxe-unstable = mkDriver unstable false;
  ext4-dxe-unstable-aarch64 = mkDriver unstable true;
}
