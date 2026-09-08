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

  debug = false;
  systems = [ "x86_64-linux" ];

  caisson = {
    configInfo.configName = "ext4-dxe";
    libOverlays.exported = libOverlays: { inherit (libOverlays) default; };
    modules = {
      flake.exported = modules: { inherit (modules) default; };
    };
  };

  # The sole package overlay, registered with caisson's nixpkgs
  # integration: it adds the `ext4-dxe` scope to nixpkgs, and is
  # exported as-is so consumers take a plain overlay and nothing else.
  caisson.nixpkgs = {
    overlays.all = {
      packages = lib.caisson.nixpkgs.mkPackagesOverlay (
        { callPackage, lib, ... }:
        import ../../../pkgs/ext4-dxe {
          inherit callPackage lib;
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
          {
            checks = {
              smoke = pkgs.runCommand "ext4-dxe-smoke-check" { } ''
                touch "$out"
              '';
              # Each driver reads a stock-mkfs.ext4 volume back byte for
              # byte from a UEFI shell (see tests/ext4-dxe-vm.nix): OVMF
              # on an emulated x86-64 machine, ArmVirtQemu on an emulated
              # AArch64 one.
              ext4-dxe-vm = import ../../../tests/ext4-dxe-vm.nix {
                inherit pkgs;
                ext4Dxe = pkgs.ext4-dxe.ext4-dxe;
              };
              ext4-dxe-vm-aarch64 = import ../../../tests/ext4-dxe-vm.nix {
                inherit pkgs;
                ext4Dxe = pkgs.ext4-dxe.ext4-dxe-aarch64;
              };
              # The same against edk2 master. These gate main's check
              # run, not a release: the release workflow builds the two
              # stable checks by name.
              ext4-dxe-vm-unstable = import ../../../tests/ext4-dxe-vm.nix {
                inherit pkgs;
                ext4Dxe = pkgs.ext4-dxe.ext4-dxe-unstable;
              };
              ext4-dxe-vm-unstable-aarch64 = import ../../../tests/ext4-dxe-vm.nix {
                inherit pkgs;
                ext4Dxe = pkgs.ext4-dxe.ext4-dxe-unstable-aarch64;
              };
            };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
