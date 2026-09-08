# SPDX-License-Identifier: MIT
# Ext4Dxe.efi: the unmodified read-only ext4 UEFI filesystem driver from
# tianocore/edk2-platforms (Features/Ext4Pkg), compiled against the edk2
# core the calling package set carries (an edk2 stable tag for the
# released driver, edk2 master for the unstable one; see ../default.nix).
# The driver verifies metadata checksums (CRC32c, including
# metadata_csum_seed), refuses filesystems with incompat features it does
# not understand, and its feature masks cover everything current
# mkfs.ext4 defaults produce (64bit, extents, flex_bg,
# metadata_csum[_seed]); unknown ro-compat features only degrade to
# read-only, which the driver always is.
#
# The target architecture follows the package set this is called from:
# nixpkgs' edk2.mkDerivation reads it from the host platform, so the
# AArch64 package set's callPackage yields the AArch64 driver from this
# same file.
{
  lib,
  stdenv,
  buildPackages,
  edk2,
  # The edk2-platforms tree; only Features/Ext4Pkg is taken from it.
  edk2-platforms,
  version,
}:
let
  targetArch =
    if stdenv.hostPlatform.isx86_64 then
      "X64"
    else if stdenv.hostPlatform.isAarch64 then
      "AARCH64"
    else
      throw "ext4-dxe: no UEFI target for ${stdenv.hostPlatform.system}";
in
edk2.mkDerivation "Features/Ext4Pkg/Ext4Pkg.dsc" {
  pname = "ext4-dxe";
  inherit version;

  # edk2's GCC toolchain (GCC5 was retired before edk2-stable202608).
  # tools_def reads the compiler prefix from these variables: GCC_BIN
  # for IA32/X64, GCC_<ARCH>_PREFIX for the others.
  buildType = "GCC";
  env = {
    GCC_BIN = stdenv.cc.targetPrefix;
    GCC_AARCH64_PREFIX = stdenv.cc.targetPrefix;
  };

  # MdePkg's BaseLib carries NASM sources on x86; AArch64 has none.
  nativeBuildInputs = lib.optional stdenv.hostPlatform.isx86 buildPackages.nasm;

  # Graft the package into the edk2 workspace at the path its DSC expects
  # ([Components] lists Features/Ext4Pkg/Ext4Dxe/Ext4Dxe.inf).
  postPatch = ''
    mkdir -p Features
    cp -r ${edk2-platforms}/Features/Ext4Pkg Features/Ext4Pkg
    chmod -R u+w Features
  '';

  installPhase = ''
    runHook preInstall
    install -D -m0644 Build/Ext4Pkg/RELEASE_*/${targetArch}/Ext4Dxe.efi \
      "$out/Ext4Dxe.efi"
    runHook postInstall
  '';

  passthru = {
    inherit targetArch;
    # What the driver was built against, for the release notes.
    edk2Version = edk2.version;
    edk2Rev = edk2.srcWithVendoring.rev;
    ext4PkgRev = edk2-platforms.rev;
  };

  meta = {
    description = "edk2-platforms Ext4Dxe: read-only ext4 UEFI filesystem driver, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Features/Ext4Pkg";
    license = lib.licenses.bsd2Patent;
    # The build host's platforms, not the driver's: the AArch64 variant
    # is cross-built and exported under packages.x86_64-linux, and a
    # narrower list would make it evaluate as unsupported there.
    platforms = lib.platforms.linux;
  };
}
