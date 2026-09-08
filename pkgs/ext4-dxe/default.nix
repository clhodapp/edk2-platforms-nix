# SPDX-License-Identifier: MIT
{ callPackage, edk2-platforms, ... }:
{
  # The x86-64 driver.
  ext4-dxe = callPackage ./ext4-dxe { inherit edk2-platforms; };

  # The same, cross-compiled for AArch64 UEFI: the driver is
  # architecture-neutral C and edk2 selects the target from the host
  # platform, so the AArch64 package set's callPackage is the whole
  # difference. Built from x86-64 (the CI runner) with nixpkgs' cross
  # toolchain.
  ext4-dxe-aarch64 = callPackage (
    { pkgsCross }: pkgsCross.aarch64-multiplatform.callPackage ./ext4-dxe { inherit edk2-platforms; }
  ) { };
}
