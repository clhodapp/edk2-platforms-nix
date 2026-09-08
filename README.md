# edk2-platforms-nix

A Nix build of TianoCore's edk2-platforms tree against edk2 stable
tags, with nixpkgs' toolchain. It releases the tree's drop-in UEFI
drivers as prebuilt binaries for x86-64 and AArch64 whenever what goes
into them changes, and carries the rest of what builds standalone as
pinned Nix expressions.

## What it is

edk2-platforms is where TianoCore keeps everything that is not the edk2
core: board firmware, silicon packages, and a handful of drivers and
feature packages that build on their own against the core. A few of
those drivers are useful loaded from an EFI System Partition on any
machine, by systemd-boot, rEFInd, a UEFI shell, or a `Driver####`
entry:

| Package | Driver | What it does | Checked by |
|---|---|---|---|
| `ext4-dxe` | Ext4Dxe | Read-only ext4 (and ext2/ext3) filesystem access, checksums verified; what lets systemd-boot read an ext4 XBOOTLDR partition | Reading a stock `mkfs.ext4` volume back byte for byte in a VM |
| `ftdi-usb-serial` | FtdiUsbSerialDxe | Serial I/O on FTDI USB-to-serial adapters, for firmware without a port of its own; x86-64 only (upstream marks it IA32/X64, and the AArch64 build faults on binding the emulated adapter) | Binding QEMU's emulated FT232 and publishing Serial I/O in a VM |
| `asix-usb-ethernet` | Ax88179, Ax88772c | Networking on ASIX USB Ethernet adapters | Loading under firmware and registering a driver binding |
| `displaylink-gop` | DisplayLinkGop | Graphics output on DisplayLink USB display adapters and docks | Loading under firmware and registering a driver binding |
| `chaoskey` | ChaosKeyDxe | The RNG protocol from a ChaosKey USB entropy device | Loading under firmware and registering a driver binding |

Each exists as `<package>` and `<package>-aarch64` under
`packages.x86_64-linux` (the AArch64 builds are cross-compiled from
there; the FTDI driver has no AArch64 variants), placing
`<Module>.efi` at the output's root, plus the `-unstable` variants
described below.

This repository adds no code to the drivers. It pins the edk2 core at a
stable tag and edk2-platforms at a commit, builds each driver's own DSC
(or, for the FTDI driver, a DSC of this repository's listing just that
module, since upstream's lists it beside modules that no longer build),
and checks every binary in a VM before release.

## Releases and versioning

Releases carry every drop-in for both architectures, named for
systemd-boot's drivers directory (`ext4_x64.efi`, `ext4_aa64.efi`,
`ftdiserial_x64.efi`, and so on), plus `SHA256SUMS`. The set is
generated from the packages' own declarations; `nix build
.#release-manifest` prints it.

A release is `v<edk2>.<revision>`:

- `edk2` is the edk2 stable tag the batch is built against
  (`edk2-stable<edk2>`). Each new tag starts a new series at revision 0.
- `revision` counts rebuilds against that tag.

Releases are created by the `release` workflow, not by hand. It runs on
every push to `main` and weekly, and three things move the version:

- edk2 tags a new stable release. The weekly run moves the pin to it
  and releases `v<newtag>.0`.
- A pin moves and any driver changes: edk2-platforms (the drivers'
  source) or nixpkgs (the toolchain), whether advanced by the weekly
  run or by the workspace's convergence. The run sees the build differ
  from the release under the current version and, since only
  `flake.lock` changed, bumps `revision` itself and releases the whole
  batch again.
- A file in this repository changes and a driver changes. The run
  fails rather than publish different bytes under an existing version;
  bumping `revision` in `pkgs/edk2-platforms-nix/version.nix` by hand
  and pushing releases it.

A pin move that leaves every driver byte-identical releases nothing.
Each release's notes name the exact edk2, edk2-platforms, and nixpkgs
commits it was built from.

## Tracking edk2 master: the unstable variants

Every drop-in also exists as `<package>-unstable` and
`<package>-unstable-aarch64`, built from the same edk2-platforms pin
against edk2 master instead of the stable tag (the `edk2-unstable-src`
input, advanced by the weekly run alongside the other pins), versioned
`0-unstable-<date>`. They are the early warning for the next stable
tag: main's check run puts them through the same VM checks as the
released builds, so an edk2 change that breaks a driver, its DSC, or
this repository's build shows up weeks before the tag that carries it.
They are never released, and a failure among them does not hold a
release; the release workflow builds only the stable variants' checks.

```bash
nix build github:clhodapp/edk2-platforms-nix#ext4-dxe-unstable
nix build github:clhodapp/edk2-platforms-nix#chaoskey-unstable-aarch64
```

## Everything else: the extras

The Intel advanced-feature packages under `Features/Intel` (ACPI debug,
POST codes, USB3 debug, IPMI, SPCR, S3, SMBIOS, boot logo, user
authentication, the virtual keyboard, and the rest) are Min Platform
integration features: their validation DSCs build the feature's PEI,
DXE, and SMM modules against MinPlatformPkg, for whoever integrates one
into a firmware image. They are useless as loose binaries and useful
as a pinned, known-to-build expression, so they are
`extras.x86_64-linux.<name>`: built best-effort by their own workflow
(`extras.yml`), with the outcome of each recorded in
`extras/STATUS.md`, never gating a check run or a release, and never
pushed to cachix. `nix build .#extras.x86_64-linux.intel-acpi-debug-feature`
builds one; the output is the whole `Build` tree.

The builder itself is `lib.edk2-platforms-nix.buildDsc`: given a
package set, an edk2 tree, an edk2-platforms tree, and a target
architecture, it returns a function that builds any DSC on the
package path (the platforms tree, its package groups, and any
directory you add) and installs the named modules. Everything above
is built through it.

## Using it

Without Nix: download the artifact from a release, check it against
`SHA256SUMS`, and copy it to `EFI/systemd/drivers/` on the EFI System
Partition (or rEFInd's `drivers_x64` / `drivers_aa64`, or `load` it
from a UEFI shell). Under Secure Boot it must be signed by a key the
platform trusts, for example
`sbsign --key db.key --cert db.crt --output ext4_x64.efi ext4_x64.efi`;
an unsigned driver is skipped.

With Nix: `overlays.packages` is a plain nixpkgs overlay adding the
packages under `pkgs.edk2-platforms-nix.*`, and
`packages.x86_64-linux.*` holds the same builds.

```bash
nix build github:clhodapp/edk2-platforms-nix#ext4-dxe
nix build github:clhodapp/edk2-platforms-nix#ftdi-usb-serial-aarch64
```

## Verification

`nix flake check` runs, for every variant of every drop-in: the ext4
read-back test (OVMF on QEMU's q35 for x86-64; nixpkgs' cross-built
ArmVirtQemu on QEMU's `virt` machine for AArch64), the FTDI test
against QEMU's `usb-serial` device, and the driver-load test for the
USB device drivers QEMU cannot emulate a device for. The release
workflow runs the stable variants' checks before publishing.

## CI

`check.yml` (on `main`) and `check-pr.yml` (on pull requests) run the
flake checks with the repository's Actions cache holding an on-disk Nix
binary cache of what the checks built, less what cache.nixos.org
serves. A pull request that leaves `.github/` alone is built by
`main`'s copy of the pipeline; one that changes it is built by its own
copy under its own cache scope. `main`'s builds are pushed to the
`clhodapp` cachix cache, which `release.yml` substitutes from.
`extras.yml` runs separately, keeps its outputs in the Actions cache
under its own key prefix, and pushes nothing to cachix.

## Binary cache

What `main` builds, every drop-in variant included, is pushed to the
`clhodapp` cachix cache, signed with its key, so `nix build` at the
same pins downloads the driver instead of building edk2's BaseTools.
That cache skips paths its upstreams already hold, so using it means
using them too:

| Substituter | Public key |
|---|---|
| `https://clhodapp.cachix.org` | `clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI=` |
| `https://nix-community.cachix.org` | `nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=` |
| `https://numtide.cachix.org` | `numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=` |

The flake's `nixConfig` declares all three, so a direct `nix build` or
`nix flake check` here uses them once accepted: answer Nix's prompt, or
pass `--accept-flake-config`. A flake that consumes this one as an
input must add them to its own `extra-substituters` and
`extra-trusted-public-keys`; Nix does not carry an input's settings
into the consumer.

## Licensing

The Nix build scaffolding, the tests, the workflows, and the one DSC
this repository authors are MIT (see `LICENSE`). The drivers are
TianoCore's, under BSD-2-Clause-Patent; their sources are not vendored
here but fetched from edk2-platforms at the pinned commit, and the
built binaries carry upstream's license.
