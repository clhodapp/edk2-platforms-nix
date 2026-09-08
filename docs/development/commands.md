# Commands

```bash
# Format
nix fmt

# Run checks
nix flake check

# Build the driver
nix build .#ext4-dxe
nix build .#ext4-dxe-aarch64
nix build .#ext4-dxe-unstable
nix build .#ext4-dxe-unstable-aarch64

# The version the next release would carry
nix eval --raw .#ext4-dxe.version
```

Advancing the revision by hand (after a change to this repository's
own files that changes the driver): edit `revision` in
`pkgs/ext4-dxe/ext4-dxe/version.nix`, commit, push to main; the release
workflow publishes the new version on that push.

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
bumps `revision` for a pin move that changed the driver, so the file
need not be edited for either.

Local iteration from a consumer flake:

```bash
nix flake check --override-input ext4-dxe path:../ext4-dxe
```
