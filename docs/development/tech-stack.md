# Technology Stack

- **Nix** for package definitions and checks
- **caisson** for closed-input `mkLib` and class-keyed module exports
  ([github:nix-caisson/caisson](https://github.com/nix-caisson/caisson))
- **nixpkgs stable** (`nixos-26.05`): the toolchain, the edk2 package
  recipe (BaseTools build, `edk2.mkDerivation`), natively and through
  `pkgsCross.aarch64-multiplatform`; OVMF / ArmVirtQemu, the UEFI
  shell, and qemu for the VM checks
- **edk2** (`edk2-src`, a stable tag; `edk2-unstable-src`, master; both
  without submodules, which hold only crypto and test libraries nothing
  here links): the core the drivers are built against, applied over
  nixpkgs' recipe as an overlay so BaseTools, the source tree, and the
  cross set agree (`lib.edk2-platforms-nix.pkgsWithEdk2`)
- **edk2-platforms**, a non-flake input pinned by commit: the drivers'
  and feature packages' source, used in place through edk2's
  `PACKAGES_PATH` (the tree and the parents of its package groups)
- **`lib.edk2-platforms-nix.buildDsc`**: the one builder every package
  and extra goes through (`pkgs/edk2-platforms-nix/build-dsc.nix`)
- **GitHub Actions** for the cached check pipeline, the automatic
  releases (`gh release`), and the best-effort extras builds
