# Testing

From the repository root:

```bash
nix flake check
```

Checks (x86_64-linux, checks partition):

- `smoke`: trivial dev-partition smoke check
- `ext4-dxe-vm`: boot OVMF's UEFI shell on an emulated q35 machine,
  `load` the x86-64 driver, `connect -r` so it binds the ext4 disk, and
  copy a 1 MiB multi-block file plus a file in a nested directory from
  a stock-`mkfs.ext4` volume back to the FAT disk; the copies are
  extracted with mtools and compared byte for byte
- `ext4-dxe-vm-aarch64`: the same against the AArch64 driver, under
  nixpkgs' cross-built ArmVirtQemu and AArch64 shell on QEMU's `virt`
  machine (full TCG emulation, so it is the slow check)
- `ext4-dxe-vm-unstable` and `ext4-dxe-vm-unstable-aarch64`: the same
  two against the drivers built on edk2 master

The release workflow builds `ext4-dxe-vm`, `ext4-dxe-vm-aarch64`, and
`treefmt` by name before publishing, so a release carries exactly the
binaries that passed them; the unstable checks run in main's check
pipeline only and never hold a release.

Gotchas: `qemu_test` builds only the host's system emulator, so the
AArch64 checks use the full `qemu` package. The ext4 image is made with
`mkfs.ext4` at stock defaults on purpose: that is the feature set
(64bit, extents, flex_bg, metadata_csum, metadata_csum_seed) a NixOS
installer produces and the driver must read. The firmware under test is
nixpkgs' OVMF, not the edk2 tree the driver is built against; the
driver has to work on firmware of any age.
