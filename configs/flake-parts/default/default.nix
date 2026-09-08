# SPDX-License-Identifier: MIT
{ ... }:
{
  config,
  inputs,
  lib,
  self,
  ...
}:
{

  imports = [ (lib.caisson.mkFlakeModule ./extras.nix) ];

  debug = false;
  systems = [ "x86_64-linux" ];

  caisson = {
    configInfo.configName = "edk2-platforms-nix";
    libOverlays.exported = libOverlays: { inherit (libOverlays) default; };
    modules = {
      flake.exported = modules: { inherit (modules) default; };
    };
  };

  # The sole package overlay, registered with caisson's nixpkgs
  # integration: it adds the `edk2-platforms-nix` scope to nixpkgs, and
  # is exported as-is so consumers take a plain overlay and nothing else.
  caisson.nixpkgs = {
    overlays.all = {
      packages =
        let
          edk2Lib = lib.edk2-platforms-nix;
        in
        lib.caisson.nixpkgs.mkPackagesOverlay (
          { callPackage, lib, ... }:
          import ../../../pkgs/edk2-platforms-nix {
            inherit callPackage lib edk2Lib;
            inherit (inputs) edk2-src edk2-unstable-src edk2-platforms;
          }
        );
    };
    overlays.export = {
      enabled = true;
    };
    overlays.exported = overlays: {
      inherit (overlays) packages;
    };
    pkgSets.pkgs = {
      pkgFunction = import inputs.nixpkgs;
      overlayImports = overlays: [ overlays.packages ];
    };
    packages.export.enabled = true;
  };

  # checks and formatter live in isolated partitions; packages deliberately
  # do not: downstream flakes consume packages.* against this flake's main
  # lock (inherited locks), so dev-only inputs must not taint them.
  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, self, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, ... }:
          let
            drivers = pkgs.edk2-platforms-nix;
            # A check for every variant a drop-in has (a driver its DSC
            # supports on one architecture only has two): the stable
            # builds gate releases (the release workflow builds them by
            # name), the edk2-master ones gate main's check run only.
            forVariants =
              name: mk:
              lib.listToAttrs (
                map (suffix: lib.nameValuePair "${name}${suffix}" (mk drivers."${name}${suffix}")) (
                  builtins.filter (suffix: drivers ? "${name}${suffix}") [
                    ""
                    "-aarch64"
                    "-unstable"
                    "-unstable-aarch64"
                  ]
                )
              );
          in
          {
            checks = {
              smoke = pkgs.runCommand "edk2-platforms-nix-smoke-check" { } ''
                touch "$out"
              '';
            }
            # Each ext4 driver reads a stock-mkfs.ext4 volume back byte
            # for byte from a UEFI shell (see tests/ext4-dxe-vm.nix):
            # OVMF on an emulated x86-64 machine, ArmVirtQemu on an
            # emulated AArch64 one.
            // forVariants "ext4-dxe" (
              ext4Dxe:
              import ../../../tests/ext4-dxe-vm.nix {
                inherit pkgs ext4Dxe;
              }
            )
            # The FTDI driver binds QEMU's emulated FT232 and publishes
            # Serial I/O on it (see tests/ftdi-serial-vm.nix).
            // forVariants "ftdi-usb-serial" (
              ftdiDriver:
              import ../../../tests/ftdi-serial-vm.nix {
                inherit pkgs ftdiDriver;
              }
            )
            # The USB device drivers QEMU cannot emulate a device for
            # load under the firmware and register their driver binding
            # (see tests/driver-load-vm.nix).
            // forVariants "asix-usb-ethernet" (
              driver:
              import ../../../tests/driver-load-vm.nix {
                inherit pkgs driver;
              }
            )
            // forVariants "displaylink-gop" (
              driver:
              import ../../../tests/driver-load-vm.nix {
                inherit pkgs driver;
              }
            )
            // forVariants "chaoskey" (
              driver:
              import ../../../tests/driver-load-vm.nix {
                inherit pkgs driver;
              }
            );
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
