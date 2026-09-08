# SPDX-License-Identifier: MIT
# Builds one DSC from the edk2-platforms tree (or from a directory given
# as an extra package path) against the edk2 core the calling package
# set carries, and installs the named modules as <BaseName>.efi at the
# output's root (or the whole build tree, for a package build).
#
# The target architecture follows the package set: nixpkgs'
# edk2.mkDerivation reads it from the host platform, so the AArch64
# package set's callPackage yields the AArch64 build from the same
# arguments. edk2's GCC toolchain is used (GCC5 was retired before
# edk2-stable202608); tools_def reads the compiler prefix from GCC_BIN
# for IA32/X64 and GCC_<ARCH>_PREFIX for the others.
{
  lib,
  stdenv,
  buildPackages,
  # nixpkgs' edk2 package over the tree the build is against (see
  # ./default.nix).
  edk2,
  # The edk2-platforms tree, on the package path as a whole.
  edk2-platforms,
  version,
}:
{
  pname,
  # The DSC, relative to a package path entry (edk2-platforms, or one of
  # extraPackagePaths).
  dsc,
  # BaseNames of the modules to install as $out/<BaseName>.efi. Empty
  # installs the whole Build tree instead (a package build).
  modules ? [ ],
  # Directories added to PACKAGES_PATH after the edk2 workspace and
  # edk2-platforms (a DSC of this repository's own, for instance).
  extraPackagePaths ? [ ],
  # Extra `build` arguments (-D defines, further -a architectures).
  buildFlags ? [ ],
  passthru ? { },
  meta ? { },
}:
let
  targetArch =
    if stdenv.hostPlatform.isx86_64 then
      "X64"
    else if stdenv.hostPlatform.isAarch64 then
      "AARCH64"
    else
      throw "${pname}: no UEFI target for ${stdenv.hostPlatform.system}";
in
edk2.mkDerivation dsc {
  inherit pname version buildFlags;

  buildType = "GCC";
  env = {
    GCC_BIN = stdenv.cc.targetPrefix;
    GCC_AARCH64_PREFIX = stdenv.cc.targetPrefix;
  };

  # MdePkg's BaseLib carries NASM sources on x86; AArch64 has none. The
  # ACPI compiler is for the packages that carry ASL tables (the Intel
  # feature packages do).
  nativeBuildInputs = [
    buildPackages.acpica-tools
  ]
  ++ lib.optional stdenv.hostPlatform.isx86 buildPackages.nasm;

  # The edk2 tree comes without submodules, and some package
  # declarations list include directories inside one (MdePkg's
  # MipiSysTLib, MdeModulePkg's brotli); the build refuses a package
  # whose declared include directory is absent, whether or not anything
  # includes from it. Each such directory is created empty.
  postPatch = ''
    for dec in $(find . -name '*.dec'); do
      awk '/^\[/ { inc = ($0 ~ /^\[Includes/) } inc && !/^\[/ { print }' "$dec" \
        | sed 's/\r$//; s/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
        > "$TMPDIR/includes"
      while read -r inc; do
        case "$inc" in
          "" | \[*) continue ;;
        esac
        mkdir -p "$(dirname "$dec")/$inc"
      done < "$TMPDIR/includes"
    done
  '';

  # edk2 resolves package-relative paths (the DSC, the INFs it names,
  # !include files) against WORKSPACE and then each PACKAGES_PATH entry,
  # so the platforms tree is used in place; only Build/ under the
  # workspace is written. The platforms tree's DSCs name components two
  # ways: relative to the tree (Drivers/ASIX/..., Silicon/Openmoko/...)
  # and relative to the package's parent (OptionRomPkg/...,
  # ManageabilityPkg/..., MinPlatformPkg/..., AcpiDebugFeaturePkg/...),
  # so the tree and the parents of its package groups are all on the
  # path, the Intel feature categories (Features/Intel/Debugging and
  # its siblings) included.
  preConfigure =
    let
      intelCategories = lib.attrNames (
        lib.filterAttrs (name: type: type == "directory" && !lib.hasSuffix "Pkg" name) (
          builtins.readDir "${edk2-platforms}/Features/Intel"
        )
      );
    in
    ''
      export PACKAGES_PATH="$PWD${
        lib.concatMapStrings (p: ":${p}") (
          [
            edk2-platforms
            "${edk2-platforms}/Drivers"
            "${edk2-platforms}/Features"
            "${edk2-platforms}/Features/Intel"
            "${edk2-platforms}/Platform/Intel"
            "${edk2-platforms}/Silicon/Intel"
          ]
          ++ map (c: "${edk2-platforms}/Features/Intel/${c}") intelCategories
          ++ extraPackagePaths
        )
      }"
    '';

  installPhase =
    if modules == [ ] then
      ''
        runHook preInstall
        mkdir -p "$out"
        mv -v Build/*/* "$out"
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        ${lib.concatMapStrings (m: ''
          install -D -m0644 Build/*/RELEASE_*/${targetArch}/${m}.efi "$out/${m}.efi"
        '') modules}
        runHook postInstall
      '';

  passthru = {
    inherit targetArch modules dsc;
    # What it was built against, for the release notes.
    edk2Version = edk2.version;
    edk2Rev = edk2.srcWithVendoring.rev;
    platformsRev = edk2-platforms.rev;
  }
  // passthru;

  meta = {
    license = lib.licenses.bsd2Patent;
    # The build host's platforms, not the target's: the AArch64 variant
    # is cross-built and exported under packages.x86_64-linux, and a
    # narrower list would make it evaluate as unsupported there.
    platforms = lib.platforms.linux;
  }
  // meta;
}
