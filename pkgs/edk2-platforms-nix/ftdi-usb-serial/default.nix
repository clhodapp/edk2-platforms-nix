# SPDX-License-Identifier: MIT
# FtdiUsbSerialDxe.efi: a UEFI driver producing the Serial I/O protocol
# on an FTDI USB-to-serial adapter (FT232 and kin), from edk2-platforms'
# OptionRomPkg. It produces the port only; the firmware's own terminal
# driver turns it into a console once the platform's ConIn/ConOut name
# it. Built through a DSC of this repository's own (dsc/) that lists
# the one module: OptionRomPkg.dsc also carries a legacy ATAPI driver,
# a Cirrus VGA driver, a Tulip UNDI, and a Renesas xHCI firmware
# loader, and its build rules no longer generate with current
# BaseTools. The driver source is untouched. x86-64 only (see
# ../default.nix).
{ buildDsc }:
buildDsc {
  pname = "ftdi-usb-serial";
  dsc = "FtdiUsbSerial.dsc";
  extraPackagePaths = [ ./dsc ];
  modules = [ "FtdiUsbSerialDxe" ];
  passthru.release = {
    FtdiUsbSerialDxe = "ftdiserial_";
  };
  meta = {
    description = "edk2-platforms FtdiUsbSerialDxe: Serial I/O on FTDI USB-to-serial adapters, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Drivers/OptionRomPkg/Bus/Usb/FtdiUsbSerialDxe";
  };
}
