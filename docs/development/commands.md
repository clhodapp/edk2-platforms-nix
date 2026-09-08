# Commands

```bash
# Format
nix fmt

# Run checks
nix flake check

# Build the driver
nix build .#ext4-dxe
nix build .#ext4-dxe-aarch64

# The version the next release would carry
nix eval --raw .#ext4-dxe.version
```

Advancing the revision (after a build-configuration change under an
unchanged upstream): edit `revision` in
`pkgs/ext4-dxe/ext4-dxe/version.nix`, commit, push to main; the release
workflow publishes the new version on that push.

Advancing the upstream pin by hand rather than waiting for the weekly
run: start the `release` workflow from the Actions tab with "advance"
checked, or run it locally and push the result:

```bash
sha=$(gh api 'repos/tianocore/edk2-platforms/commits?sha=master&path=Features/Ext4Pkg&per_page=1' --jq '.[0].sha')
nix flake lock --override-input edk2-platforms "github:tianocore/edk2-platforms/$sha"
```

The workflow reconciles `upstream` in `version.nix` from the pushed
lock, so the file need not be edited for a pin move.

Local iteration from a consumer flake:

```bash
nix flake check --override-input ext4-dxe path:../ext4-dxe
```
