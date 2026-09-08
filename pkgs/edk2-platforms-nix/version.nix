# SPDX-License-Identifier: MIT
#
# The batch's version, `<edk2>.<revision>`; a release is tagged
# `v<edk2>.<revision>` and carries every drop-in driver at once.
#
# `edk2` is the edk2 stable tag the batch is built against
# (`edk2-stable<edk2>`), the same tag the `edk2-src` input in flake.nix
# names. The release workflow maintains this field from the lock and
# moves both to each new stable tag with `revision` back at 0; do not
# edit it by hand.
#
# `revision` counts rebuilds against the same edk2 tag. The release
# workflow advances it by itself when a pin move (edk2-platforms, the
# drivers' source; nixpkgs, the toolchain; anything else in flake.lock)
# changes any released driver. A change to a file this repository
# authors that changes a driver is advanced by hand: the workflow
# refuses to publish drivers that differ from the ones released under
# the same version, and that refusal on a push to main is the signal to
# bump this.
{
  edk2 = "202608";
  revision = 1;
}
