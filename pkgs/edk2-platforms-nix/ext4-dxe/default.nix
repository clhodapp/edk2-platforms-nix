# SPDX-License-Identifier: MIT
# Ext4Dxe.efi: the unmodified read-only ext4 UEFI filesystem driver from
# tianocore/edk2-platforms (Features/Ext4Pkg). It verifies metadata
# checksums (CRC32c, including metadata_csum_seed), refuses filesystems
# with incompat features it does not understand, and its feature masks
# cover everything current mkfs.ext4 defaults produce (64bit, extents,
# flex_bg, metadata_csum[_seed]); unknown ro-compat features only
# degrade to read-only, which the driver always is. It reads ext2 and
# ext3 volumes too, ext4 being a superset on disk.
{ buildDsc }:
buildDsc {
  pname = "ext4-dxe";
  dsc = "Features/Ext4Pkg/Ext4Pkg.dsc";
  modules = [ "Ext4Dxe" ];
  passthru.release = {
    # The release asset's basename, before the architecture suffix
    # systemd-boot requires (ext4_x64.efi, ext4_aa64.efi).
    Ext4Dxe = "ext4_";
  };
  meta = {
    description = "edk2-platforms Ext4Dxe: read-only ext4 UEFI filesystem driver, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Features/Ext4Pkg";
  };
}
