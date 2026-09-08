# SPDX-License-Identifier: MIT
{

  description = "Ext4Dxe: edk2-platforms' read-only ext4 UEFI filesystem driver, built from the pinned tree for x86-64 and AArch64";

  # Honored only when this flake is evaluated directly (`nix build`,
  # `nix flake check`) and the settings are accepted: answer the prompt,
  # or pass `--accept-flake-config` (a non-interactive run otherwise
  # ignores them with a warning). A consumer that takes this flake as an
  # input gets nothing from it and must declare the caches itself. The
  # two upstreams are part of the deal: the clhodapp cache skips
  # uploading paths they already hold.
  nixConfig = {
    extra-substituters = [
      "https://clhodapp.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  inputs = {
    caisson.url = "github:nix-caisson/caisson";

    # Stable channel on purpose: a boot-path firmware artifact should churn
    # as little as possible, and nothing here needs bleeding-edge nixpkgs.
    # The edk2 core and toolchain the driver is built with come from here.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # The driver's source tree. Only Features/Ext4Pkg is used. The lock
    # pins the commit; the release workflow keeps it at the newest commit
    # touching that directory and derives the version from that commit's
    # date (see pkgs/ext4-dxe/ext4-dxe/version.nix).
    edk2-platforms.url = "github:tianocore/edk2-platforms";
    edk2-platforms.flake = false;
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit inputs;

        projects = {
          inherit caisson;
        };

        modules = lib: {
          flake = {
            default = lib.caisson.mkFlakeModule ./modules/flake-parts/default;
          };
        };

        libOverlays = mkLibOverlay: {
          default = mkLibOverlay ./lib-overlays/default;
        };
      };
    in
    lib.caisson.mkFlake {
      name = "ext4-dxe";
      configModule = lib.caisson.mkFlakeModule ./configs/flake-parts/default;
    };

}
