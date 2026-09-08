# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    edk2-platforms-nix = (prev.edk2-platforms-nix or { }) // {

      # A nixpkgs package set whose edk2 (the BaseTools build and the
      # source tree edk2.mkDerivation compiles in) is the given tree,
      # applied as an overlay on the whole set: edk2.mkDerivation takes
      # BaseTools from buildPackages.edk2, and AArch64 builds come from
      # pkgsCross, so a per-package override would leave those at
      # nixpkgs' own edk2.
      #
      # The tree is used as shipped, without submodules. nixpkgs' recipe
      # patches its own tree for the GCC5 toolchain (reading the prefix
      # from the environment) and de-vendors OpenSSL; from
      # edk2-stable202608 GCC5 is gone and the GCC toolchain reads its
      # prefix from the environment already (see
      # pkgs/edk2-platforms-nix/build-dsc.nix), and nothing built this
      # way uses CryptoPkg. The BaseTools build is the one place a
      # submodule is compiled (BrotliCompress, from the brotli tree
      # under MdeModulePkg); no DSC build runs it, so it is left out.
      pkgsWithEdk2 =
        {
          pkgs,
          src,
          edk2Version,
        }:
        pkgs.extend (
          final: prev: {
            edk2 = prev.edk2.overrideAttrs (_: {
              version = edk2Version;
              srcWithVendoring = src;
              inherit src;
              # The makefile has CRLF line endings, hence the loose pattern.
              postPatch = ''
                sed -i '/^  BrotliCompress \\/d' BaseTools/Source/C/GNUmakefile
                ! grep -q BrotliCompress BaseTools/Source/C/GNUmakefile
              '';
            });
          }
        );

      # The DSC builder over a package set, an edk2 tree, and an
      # edk2-platforms tree, for one target architecture. Returns the
      # function documented in pkgs/edk2-platforms-nix/build-dsc.nix.
      # The toolchain and BaseTools come from `pkgs` (built natively);
      # the AArch64 target uses its aarch64-multiplatform cross set.
      buildDsc =
        {
          pkgs,
          # The edk2 tree (a store path) and the version to label it.
          edk2Src,
          edk2Version,
          # The edk2-platforms tree.
          platformsSrc,
          # The version the built packages carry.
          version,
          arch ? "X64",
        }:
        let
          withEdk2 = final.edk2-platforms-nix.pkgsWithEdk2 {
            inherit pkgs edk2Version;
            src = edk2Src;
          };
          pkgsForTarget = if arch == "AARCH64" then withEdk2.pkgsCross.aarch64-multiplatform else withEdk2;
        in
        pkgsForTarget.callPackage ../../pkgs/edk2-platforms-nix/build-dsc.nix {
          inherit version;
          edk2-platforms = platformsSrc;
        };
    };
  };

}
