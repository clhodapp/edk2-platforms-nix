# SPDX-License-Identifier: MIT
#
# `extras.<system>.<name>`: builds of edk2-platforms packages that are
# not drop-in drivers, kept out of `packages` and `checks` on purpose.
# They are the Intel advanced-feature packages' validation DSCs (each
# builds the feature's PEI, DXE, and SMM modules against MinPlatformPkg,
# for whoever integrates one into a firmware image), useful as a
# pinned, known-to-build Nix expression rather than as binaries. They
# are built best-effort by extras.yml, never gate a check run or a
# release, and are never pushed to cachix; `nix build .#extras.<system>.<name>`
# builds one locally.
{ ... }:
{
  config,
  inputs,
  lib,
  ...
}:
let
  version = import ../../../pkgs/edk2-platforms-nix/version.nix;

  # x86 only, as their DSCs say (IA32 for PEI, X64 for DXE and SMM), so
  # the stable X64 builder with IA32 added.
  intelFeatures = {
    intel-advanced-feature-pkg = "Features/Intel/AdvancedFeaturePkg/AdvancedFeaturePkg.dsc";
    intel-acpi-debug-feature = "Features/Intel/Debugging/AcpiDebugFeaturePkg/AcpiDebugFeaturePkg.dsc";
    intel-beep-debug-feature = "Features/Intel/Debugging/BeepDebugFeaturePkg/BeepDebugFeaturePkg.dsc";
    intel-post-code-debug-feature = "Features/Intel/Debugging/PostCodeDebugFeaturePkg/PostCodeDebugFeaturePkg.dsc";
    intel-usb3-debug-feature = "Features/Intel/Debugging/Usb3DebugFeaturePkg/Usb3DebugFeaturePkg.dsc";
    intel-network-feature = "Features/Intel/Network/NetworkFeaturePkg/NetworkFeaturePkg.dsc";
    intel-asf-feature = "Features/Intel/OutOfBandManagement/AsfFeaturePkg/AsfFeaturePkg.dsc";
    intel-ipmi-feature = "Features/Intel/OutOfBandManagement/IpmiFeaturePkg/IpmiFeaturePkg.dsc";
    intel-spcr-feature = "Features/Intel/OutOfBandManagement/SpcrFeaturePkg/SpcrFeaturePkg.dsc";
    intel-platform-payload-feature = "Features/Intel/PlatformPayloadFeaturePkg/PlatformPayloadFeaturePkg.dsc";
    intel-s3-feature = "Features/Intel/PowerManagement/S3FeaturePkg/S3FeaturePkg.dsc";
    intel-smbios-feature = "Features/Intel/SystemInformation/SmbiosFeaturePkg/SmbiosFeaturePkg.dsc";
    intel-template-feature = "Features/Intel/TemplateFeaturePkg/TemplateFeaturePkg.dsc";
    intel-logo-feature = "Features/Intel/UserInterface/LogoFeaturePkg/LogoFeaturePkg.dsc";
    intel-user-auth-feature = "Features/Intel/UserInterface/UserAuthFeaturePkg/UserAuthFeaturePkg.dsc";
    intel-virtual-keyboard-feature = "Features/Intel/UserInterface/VirtualKeyboardFeaturePkg/VirtualKeyboardFeaturePkg.dsc";
  };

  extrasFor =
    system:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      buildDsc = lib.edk2-platforms-nix.buildDsc {
        inherit pkgs;
        edk2Src = inputs.edk2-src;
        edk2Version = version.edk2;
        platformsSrc = inputs.edk2-platforms;
        version = "${version.edk2}.${toString version.revision}";
        arch = "X64";
      };
    in
    lib.mapAttrs (
      name: dsc:
      buildDsc {
        pname = name;
        inherit dsc;
        # PlatformPayloadFeaturePkg is X64 only; the rest pair IA32 PEI
        # with X64 DXE.
        buildFlags = lib.optionals (name != "intel-platform-payload-feature") [
          "-a"
          "IA32"
        ];
        meta.description = "edk2-platforms ${baseNameOf (dirOf dsc)} validation build against the pinned edk2 and MinPlatformPkg";
      }
    ) intelFeatures;
in
{
  flake.extras = lib.genAttrs config.systems extrasFor;
}
