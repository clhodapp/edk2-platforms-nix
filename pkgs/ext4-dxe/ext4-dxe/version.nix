# SPDX-License-Identifier: MIT
#
# The driver's version, `<upstream>.<revision>`; a release is tagged
# `v<upstream>.<revision>`.
#
# `upstream` is the committer date of the newest tianocore/edk2-platforms
# commit that touches Features/Ext4Pkg and is reachable from the locked
# `edk2-platforms` input. Ext4Pkg carries no version of its own and
# edk2-platforms has no releases, so the date of the driver's last source
# change stands as its version. The release workflow maintains this field
# from the lock (and resets `revision` to 0 when it changes); do not edit
# it by hand.
#
# `revision` is this repository's. Advance it by hand when the build
# configuration changes under an unchanged upstream (a nixpkgs bump that
# moves the edk2 core or the toolchain, a change to the Nix here) and the
# released binaries should be replaced. The release workflow refuses to
# proceed when the driver it builds differs from the one released under
# the same version, so a change that needs a bump is caught on the next
# push to main.
{
  upstream = "20260403";
  revision = 0;
}
