Prebuilt UEFI drivers from TianoCore's edk2-platforms, built unmodified against an edk2 stable tag, for use without Nix. Each comes as `<name>x64.efi` for x86-64 and `<name>aa64.efi` for AArch64.

| Artifact | Driver | What it does | Verified by |
|---|---|---|---|
| `ext4_*.efi` | Ext4Dxe (`Features/Ext4Pkg`) | Read-only ext4 (and ext2/ext3) filesystem access; verifies metadata checksums | Reads a stock `mkfs.ext4` volume back byte for byte in a VM |
| `ftdiserial_x64.efi` | FtdiUsbSerialDxe (`Drivers/OptionRomPkg`) | Serial I/O on FTDI USB-to-serial adapters; x86-64 only (upstream marks the module IA32/X64, and an AArch64 build faults on binding the emulated adapter) | Binds QEMU's emulated FT232 and publishes Serial I/O in a VM |
| `ax88179_*.efi`, `ax88772c_*.efi` | Ax88179, Ax88772c (`Drivers/ASIX`) | Networking on ASIX USB 3.0 gigabit and USB 2.0 Ethernet adapters | Loads under firmware and registers its driver binding in a VM |
| `displaylink_*.efi` | DisplayLinkGop (`Drivers/DisplayLink`) | Graphics output on DisplayLink USB display adapters and docks | Loads under firmware and registers its driver binding in a VM |
| `chaoskey_*.efi` | ChaosKeyDxe (`Silicon/Openmoko`) | The RNG protocol from a ChaosKey USB entropy device | Loads under firmware and registers its driver binding in a VM |

Verify a download against `SHA256SUMS` before installing it.

## Versioning

A release is `v<edk2>.<revision>`. `<edk2>` is the edk2 stable tag the batch is built against (`edk2-stable<edk2>`); each new stable tag starts a new series at revision 0. `<revision>` counts rebuilds against that tag: it advances whenever a move of the drivers' source (edk2-platforms) or of the toolchain (nixpkgs) changes any of the binaries, and when this repository's own build configuration changes. Every driver and both architectures are built together from one commit, so a release always carries the whole set. The "This release" table below names the exact commits.

## Supported platforms

x86-64 and AArch64 UEFI. Only the ext4 and FTDI drivers are exercised against a device before release, in QEMU (TianoCore OVMF on x86-64, edk2's ArmVirtQemu on AArch64); the others are loaded under that firmware and checked to register a driver binding, which is what can be verified without the hardware. The x86-64 ext4 driver is in use under systemd-boot on real hardware; nothing else here has been run on real hardware by this repository.

## Provenance

The artifacts are the store paths the repository's CI built for the tagged commit, copied out and renamed; they are byte-identical to what `nix build .#<attribute>` produces at that commit, which is one way to check a download beyond `SHA256SUMS`.

## Installing

For systemd-boot, copy the artifact to `EFI/systemd/drivers/` on the EFI System Partition, keeping the `x64.efi` (or `aa64.efi`) filename suffix, which systemd-boot requires; systemd-boot loads every driver there before reading its entries. rEFInd loads drivers from its `drivers_x64` (or `drivers_aa64`) directory, and a UEFI shell on `load`. A `Driver####` NVRAM entry (`efibootmgr --driver --create`) makes the firmware itself load one.

The FTDI driver produces a serial port; making it a console is the platform's `ConIn`/`ConOut` configuration, which this driver does not touch.

## Secure Boot

If Secure Boot is enabled, a driver must be signed by a key your platform's signature database trusts, or the firmware will skip it. Signing with your own db key:

```
sbsign --key db.key --cert db.crt \
  --output ext4_x64.efi ext4_x64.efi
```
