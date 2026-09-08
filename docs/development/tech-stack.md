# Technology Stack

- **Nix** for package definitions and checks
- **caisson** for closed-input `mkLib` and class-keyed module exports
  ([github:nix-caisson/caisson](https://github.com/nix-caisson/caisson))
- **nixpkgs stable** (`nixos-26.05`): the toolchain, the edk2 package
  recipe (BaseTools build, OpenSSL de-vendoring, `edk2.mkDerivation`),
  natively and through `pkgsCross.aarch64-multiplatform`; OVMF /
  ArmVirtQemu, the UEFI shell, and qemu for the VM checks
- **edk2** (`edk2-src`, a stable tag with submodules; `edk2-unstable-src`,
  master): the core the driver is built against, applied over nixpkgs'
  recipe as an overlay so BaseTools, the source tree, and the cross set
  agree
- **edk2-platforms** (`Features/Ext4Pkg`), a non-flake input pinned by
  commit: the driver's source, grafted into the edk2 workspace and
  built through its own DSC
- **GitHub Actions** for the cached check pipeline and the automatic
  releases (`gh release`)
