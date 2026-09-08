# Testing

From the repository root:

```bash
nix flake check
```

Checks (x86_64-linux, checks partition), each for the four variants of
a drop-in (`<name>`, `-aarch64`, `-unstable`, `-unstable-aarch64`):

- `ext4-dxe*`: boot the UEFI shell (OVMF on QEMU's q35 for x86-64;
  nixpkgs' cross-built ArmVirtQemu and AArch64 shell on QEMU's `virt`
  machine for AArch64), `load` the driver, `connect -r` so it binds
  the ext4 disk, and copy a 1 MiB multi-block file plus a file in a
  nested directory from a stock-`mkfs.ext4` volume back to the FAT
  disk; the copies are extracted with mtools and compared byte for
  byte (`tests/ext4-dxe-vm.nix`)
- `ftdi-usb-serial*` (x86-64 variants only): the same boot with QEMU's
  `usb-serial` device (an emulated FTDI FT232) behind an xHCI
  controller; after `load` and `connect -r`, a Serial I/O handle on a
  USB device path must exist (`tests/ftdi-serial-vm.nix`). The driver's
  initial baud and data-bits requests get a stall from the emulation
  that real adapters do not give; the driver's DSC compiles its asserts
  out for RELEASE (as DisplayLink's does), so the port is published
  unconfigured rather than the firmware stopping. The AArch64 build
  faulted on binding the emulated adapter, which is why the driver is
  x86-64 only.
- `asix-usb-ethernet*`, `displaylink-gop*`, `chaoskey*`: `load` each
  module and require a success status and the driver's presence in the
  shell's driver table, which a driver-model driver reaches only by
  installing its driver binding; the most a USB device driver can be
  checked without its device (`tests/driver-load-vm.nix`)
- `smoke` and `treefmt`

The release workflow builds the stable variants' checks by name before
publishing, so a release carries exactly the binaries that passed
them; the `-unstable` checks run in main's check pipeline only and
never hold a release. The extras have no checks; `extras.yml` builds
them and records the outcome.

Gotchas: `qemu_test` builds only the host's system emulator, so the
AArch64 checks use the full `qemu` package, under TCG, which makes them
the slow ones. The shell writes its redirected output as UCS-2; the
tests strip the NUL bytes before grepping. The ext4 image is made with
`mkfs.ext4` at stock defaults on purpose: that is the feature set
(64bit, extents, flex_bg, metadata_csum, metadata_csum_seed) a NixOS
installer produces and the driver must read. The firmware under test is
nixpkgs' OVMF, not the edk2 tree the drivers are built against; a
driver has to work on firmware of any age.
