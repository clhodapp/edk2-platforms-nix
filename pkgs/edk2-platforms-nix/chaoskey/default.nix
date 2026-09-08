# SPDX-License-Identifier: MIT
# ChaosKeyDxe.efi: a UEFI driver producing the RNG protocol from an
# Altus Metrum ChaosKey, a USB hardware random number generator, for
# firmware with no entropy source of its own. From edk2-platforms'
# Silicon/Openmoko, whose Openmoko.dsc builds this one module.
{ buildDsc }:
buildDsc {
  pname = "chaoskey";
  dsc = "Silicon/Openmoko/Openmoko.dsc";
  modules = [ "ChaosKeyDxe" ];
  passthru.release = {
    ChaosKeyDxe = "chaoskey_";
  };
  meta = {
    description = "edk2-platforms ChaosKeyDxe: the RNG protocol from a ChaosKey USB entropy device, built unmodified from the pinned tree";
    homepage = "https://github.com/tianocore/edk2-platforms/tree/master/Silicon/Openmoko/ChaosKeyDxe";
  };
}
