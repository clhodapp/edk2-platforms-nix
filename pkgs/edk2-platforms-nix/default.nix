# SPDX-License-Identifier: MIT
{
  lib,
  callPackage,
  # lib.edk2-platforms-nix from this flake's lib overlay.
  edk2Lib,
  edk2-src,
  edk2-unstable-src,
  edk2-platforms,
  ...
}:
let
  version = import ./version.nix;

  # The two edk2 cores: the stable tag the releases are built against,
  # and master as last advanced (built and checked, never released).
  cores = {
    stable = {
      src = edk2-src;
      edk2Version = version.edk2;
      buildVersion = "${version.edk2}.${toString version.revision}";
    };
    unstable = rec {
      src = edk2-unstable-src;
      edk2Version = "0-unstable-${lib.substring 0 8 edk2-unstable-src.lastModifiedDate}";
      buildVersion = edk2Version;
    };
  };

  # Every (core, target) a build can be made for, with the attribute
  # suffix it gets.
  variants = [
    {
      suffix = "";
      core = cores.stable;
      arch = "X64";
      released = true;
    }
    {
      suffix = "-aarch64";
      core = cores.stable;
      arch = "AARCH64";
      released = true;
    }
    {
      suffix = "-unstable";
      core = cores.unstable;
      arch = "X64";
      released = false;
    }
    {
      suffix = "-unstable-aarch64";
      core = cores.unstable;
      arch = "AARCH64";
      released = false;
    }
  ];

  # The DSC builder for a variant, over this package set (callPackage's
  # own, reached through it).
  buildDscFor =
    v:
    callPackage (
      { pkgs }:
      edk2Lib.buildDsc {
        inherit pkgs;
        inherit (v) arch;
        edk2Src = v.core.src;
        edk2Version = v.core.edk2Version;
        platformsSrc = edk2-platforms;
        version = v.core.buildVersion;
      }
    ) { };

  # The drop-in drivers: standalone DSCs whose modules load from an
  # EFI System Partition. Each file takes `buildDsc` and names its
  # release assets in passthru.release; a variant is generated for
  # every target its DSC supports.
  both = [
    "X64"
    "AARCH64"
  ];
  dropIns = {
    ext4-dxe = {
      file = ./ext4-dxe;
      arches = both;
    };
    # x86-64 only: upstream marks the module valid for IA32 and X64,
    # and the AArch64 build takes a synchronous exception as soon as it
    # binds QEMU's emulated FT232 under ArmVirtQemu.
    ftdi-usb-serial = {
      file = ./ftdi-usb-serial;
      arches = [ "X64" ];
    };
    asix-usb-ethernet = {
      file = ./asix-usb-ethernet;
      arches = both;
    };
    displaylink-gop = {
      file = ./displaylink-gop;
      arches = both;
    };
    chaoskey = {
      file = ./chaoskey;
      arches = both;
    };
  };
  dropInVariants = lib.concatMapAttrs (
    name: d:
    lib.listToAttrs (
      map (v: lib.nameValuePair "${name}${v.suffix}" (callPackage d.file { buildDsc = buildDscFor v; })) (
        builtins.filter (v: builtins.elem v.arch d.arches) variants
      )
    )
  ) dropIns;

  # What a release carries: for each released variant of each drop-in,
  # the package attribute, the module, and the asset name (the
  # architecture suffix systemd-boot's drivers directory requires).
  archSuffix = {
    X64 = "x64";
    AARCH64 = "aa64";
  };
  releaseManifest = lib.concatLists (
    lib.mapAttrsToList (
      name: d:
      lib.concatMap (
        v:
        let
          pkg = dropInVariants."${name}${v.suffix}";
        in
        lib.mapAttrsToList (module: prefix: {
          attr = "${name}${v.suffix}";
          inherit module;
          file = "${prefix}${archSuffix.${v.arch}}.efi";
        }) pkg.release
      ) (builtins.filter (v: v.released && builtins.elem v.arch d.arches) variants)
    ) dropIns
  );
in
dropInVariants
// {
  # The release workflow reads this to know what to build and how to
  # name it.
  release-manifest = callPackage (
    { writeText }: writeText "release-manifest.json" (builtins.toJSON releaseManifest)
  ) { };
}
