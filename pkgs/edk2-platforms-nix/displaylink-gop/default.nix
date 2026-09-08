# SPDX-License-Identifier: MIT
# DisplayLinkGop.efi: a UEFI driver producing the Graphics Output
# protocol on DisplayLink USB display adapters and docks, from
# edk2-platforms' Drivers/DisplayLink. The DSC passes
# INF_DRIVER_VERSION through to the compiler without defining it
# itself; the INF's own value is given here so the define is never
# empty.
{ buildDsc }:
buildDsc {
  pname = "displaylink-gop";
  dsc = "Drivers/DisplayLink/DisplayLinkPkg/DisplayLinkPkg.dsc";
  buildFlags = [ "-D INF_DRIVER_VERSION=0x00000001" ];
  modules = [ "DisplayLinkGop" ];
  passthru.release = {
    DisplayLinkGop = "displaylink_";
  };
  meta = {
    description = "edk2-platforms DisplayLinkGop: Graphics Output on DisplayLink USB display adapters, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Drivers/DisplayLink";
  };
}
