# Commands

```bash
# Format
nix fmt

# Run checks
nix flake check

# Build a driver (any of ext4-dxe, ftdi-usb-serial, asix-usb-ethernet,
# displaylink-gop, chaoskey; suffixes -aarch64, -unstable,
# -unstable-aarch64)
nix build .#ext4-dxe
nix build .#ftdi-usb-serial-aarch64

# What the next release would carry, and its version
nix build .#release-manifest -o manifest && cat manifest
nix eval --raw .#ext4-dxe.version

# Build an extra (the output is the whole edk2 Build tree)
nix build .#extras.x86_64-linux.intel-acpi-debug-feature
```

Adding a drop-in: a file `pkgs/edk2-platforms-nix/<name>/default.nix`
taking `{ buildDsc }` and naming its DSC, its modules, and their
release asset prefixes in `passthru.release`; a line in
`pkgs/edk2-platforms-nix/default.nix`'s `dropIns` with the
architectures its DSC supports; and checks in
`configs/flake-parts/default/default.nix` through `forVariants`. The
release manifest and the release workflow pick it up from there.

Advancing the revision by hand (after a change to this repository's
own files that changes a driver): edit `revision` in
`pkgs/edk2-platforms-nix/version.nix`, commit, push to main; the
release workflow publishes the new version on that push.

Advancing the pins by hand rather than waiting for the weekly run:
start the `release` workflow from the Actions tab with "advance"
checked. Locally, the same moves are:

```bash
# edk2-platforms and edk2 master
nix flake update edk2-platforms edk2-unstable-src

# a new edk2 stable tag: change the tag in flake.nix's edk2-src.url, then
nix flake update edk2-src
```

The workflow reconciles `edk2` in `version.nix` from the pushed lock and
bumps `revision` for a pin move that changed a driver, so the file
need not be edited for either.

Local iteration from a consumer flake:

```bash
nix flake check --override-input edk2-platforms-nix path:../edk2-platforms-nix
```
