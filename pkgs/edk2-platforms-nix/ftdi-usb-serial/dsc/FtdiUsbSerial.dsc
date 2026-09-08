## @file
#  Builds edk2-platforms' FtdiUsbSerialDxe on its own. OptionRomPkg.dsc
#  lists it beside a legacy ATAPI driver, a Cirrus VGA driver, a Tulip
#  UNDI, and a Renesas xHCI firmware loader, and its build rules no
#  longer generate cleanly with current BaseTools; the module itself has
#  no dependency outside MdePkg and OptionRomPkg's own DEC. The library
#  mappings and PCDs are OptionRomPkg.dsc's.
#
#  SPDX-License-Identifier: MIT
##

[Defines]
  PLATFORM_NAME                  = FtdiUsbSerial
  PLATFORM_GUID                  = 6f2c4d1e-8b0a-4e3d-9c7f-2a1b3c4d5e6f
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/FtdiUsbSerial
  SUPPORTED_ARCHITECTURES        = IA32|X64|AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE
  SKUID_IDENTIFIER               = DEFAULT

[SkuIds]
  0|DEFAULT

# A release build without live asserts, as DisplayLinkPkg.dsc does:
# the driver asserts on a failed setup request to the adapter, which
# would stop the firmware instead of leaving the port unconfigured.
[BuildOptions]
  GCC:RELEASE_*_*_CC_FLAGS  = -DMDEPKG_NDEBUG
  MSFT:RELEASE_*_*_CC_FLAGS = /D MDEPKG_NDEBUG

!include MdePkg/MdeLibs.dsc.inc

[LibraryClasses]
  DebugLib|MdePkg/Library/UefiDebugLibStdErr/UefiDebugLibStdErr.inf
  DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  TimerLib|MdePkg/Library/BaseTimerLibNullTemplate/BaseTimerLibNullTemplate.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
  UefiDriverEntryPoint|MdePkg/Library/UefiDriverEntryPoint/UefiDriverEntryPoint.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  HobLib|MdePkg/Library/DxeHobLib/DxeHobLib.inf

[PcdsFixedAtBuild]
  gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x27
  gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x80000042
  gEfiMdePkgTokenSpaceGuid.PcdDebugClearMemoryValue|0x0
  gEfiMdePkgTokenSpaceGuid.PcdMaximumUnicodeStringLength|0x0
  gEfiMdePkgTokenSpaceGuid.PcdMaximumAsciiStringLength|0x0
  gEfiMdePkgTokenSpaceGuid.PcdMaximumLinkedListLength|0x0

[Components]
  OptionRomPkg/Bus/Usb/FtdiUsbSerialDxe/FtdiUsbSerialDxe.inf
