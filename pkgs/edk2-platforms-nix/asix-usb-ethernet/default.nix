# SPDX-License-Identifier: MIT
# Ax88179.efi and Ax88772c.efi: UEFI drivers producing the Simple
# Network protocol on ASIX AX88179 (USB 3.0 gigabit) and AX88772C
# (USB 2.0 fast Ethernet) adapters, from edk2-platforms' Drivers/ASIX.
# edk2 core's own USB network class drivers (CDC ECM, CDC NCM, RNDIS)
# cover many other adapters; these cover the two ASIX chips, which
# present a vendor protocol instead.
{ buildDsc }:
buildDsc {
  pname = "asix-usb-ethernet";
  dsc = "Drivers/ASIX/Asix.dsc";
  modules = [
    "Ax88179"
    "Ax88772c"
  ];
  passthru.release = {
    Ax88179 = "ax88179_";
    Ax88772c = "ax88772c_";
  };
  meta = {
    description = "edk2-platforms ASIX AX88179 and AX88772C USB Ethernet drivers, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Drivers/ASIX";
  };
}
