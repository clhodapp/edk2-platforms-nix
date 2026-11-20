# SPDX-License-Identifier: MIT
#
# The checks of edk2-platforms-nix: a flake-parts configuration declared
# inside the flake-parts caisson top (configs/flake/edk2-platforms-nix),
# whose dependencies are those of the caisson top with the pins of
# tests/dependencies beside them. The caisson top gathers the checks
# declared here into its `checks` output. A flake that lists
# edk2-platforms-nix as an input reads nothing of this configuration, so
# it locks none of the pins of tests/dependencies.
{ ... }:
{ inputs, lib, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    let
      drivers = pkgs.edk2-platforms-nix;
      # A check for every variant a drop-in has (a driver its DSC
      # supports on one architecture only has two), named as the
      # variant: the stable builds gate releases (the release workflow
      # builds them by name), the edk2-master ones gate main's check run
      # only.
      forVariants =
        name: description: mk:
        lib.listToAttrs (
          map
            (
              suffix:
              lib.nameValuePair "${name}${suffix}" {
                derivation = mk drivers."${name}${suffix}";
                category = "vm";
                description = "${description} (${name}${suffix})";
              }
            )
            (
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
      # Duplicated in the formatter partition of
      # configs/flake/edk2-platforms-nix: the partition and this
      # configuration are separate evaluations.
      treefmt.programs.nixfmt.enable = true;

      caisson.checks = {
        treefmt = {
          category = "format";
          description = "the Nix files are formatted with nixfmt";
        };
        smoke = {
          derivation = pkgs.runCommand "edk2-platforms-nix-smoke-check" { } ''
            touch "$out"
          '';
          category = "eval";
          description = "the configuration that holds the checks evaluates";
        };
      }
      # OVMF on an emulated x86-64 machine, ArmVirtQemu on an emulated
      # AArch64 one; see tests/ext4-dxe-vm.nix.
      //
        forVariants "ext4-dxe"
          "the ext4 driver reads a stock mkfs.ext4 volume back byte for byte from a UEFI shell"
          (
            ext4Dxe:
            import ../../../tests/ext4-dxe-vm.nix {
              inherit pkgs ext4Dxe;
            }
          )
      # See tests/ftdi-serial-vm.nix.
      //
        forVariants "ftdi-usb-serial"
          "the FTDI driver binds the emulated FT232 of QEMU and publishes Serial I/O on it"
          (
            ftdiDriver:
            import ../../../tests/ftdi-serial-vm.nix {
              inherit pkgs ftdiDriver;
            }
          )
      # QEMU emulates no device for these USB drivers; see
      # tests/driver-load-vm.nix.
      //
        forVariants "asix-usb-ethernet"
          "the driver loads under the firmware and registers its driver binding"
          (
            driver:
            import ../../../tests/driver-load-vm.nix {
              inherit pkgs driver;
            }
          )
      //
        forVariants "displaylink-gop" "the driver loads under the firmware and registers its driver binding"
          (
            driver:
            import ../../../tests/driver-load-vm.nix {
              inherit pkgs driver;
            }
          )
      // forVariants "chaoskey" "the driver loads under the firmware and registers its driver binding" (
        driver:
        import ../../../tests/driver-load-vm.nix {
          inherit pkgs driver;
        }
      );
    };
}
