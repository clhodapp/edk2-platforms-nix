# SPDX-License-Identifier: MIT
# Proves a driver loads under real firmware: the UEFI shell `load`s each
# of the package's modules, and the check requires the load to succeed
# and the driver to appear in the shell's driver table afterwards, which
# a UEFI driver-model driver reaches only by installing its driver
# binding from its entry point. With no matching device attached this
# is the whole of what can be verified for a USB device driver in a VM;
# it catches a module built for the wrong architecture, a missing
# dependency, and an entry point that fails.
#
# The firmware, shell, boot file name, and machine follow the driver's
# architecture, as in ext4-dxe-vm.nix.
{ pkgs, driver }:
let
  aarch64 = driver.stdenv.hostPlatform.isAarch64;
  targetPkgs = if aarch64 then pkgs.pkgsCross.aarch64-multiplatform else pkgs;
  ovmf = targetPkgs.OVMF;
  shell = targetPkgs.edk2-uefi-shell;
  bootFile = if aarch64 then "BOOTAA64.EFI" else "BOOTX64.EFI";
  qemu =
    if aarch64 then
      "qemu-system-aarch64 -machine virt -cpu cortex-a57"
    else
      "qemu-system-x86_64 -machine q35";
in
pkgs.runCommand "${driver.pname}-load-check${pkgs.lib.optionalString aarch64 "-aarch64"}"
  {
    nativeBuildInputs = [
      (if aarch64 then pkgs.qemu else pkgs.qemu_test)
      pkgs.mtools
      pkgs.dosfstools
    ];
  }
  ''
    truncate -s 16M esp.img
    mkfs.vfat esp.img
    mmd -i esp.img ::/EFI ::/EFI/BOOT

    {
      echo '@echo -off'
      ${pkgs.lib.concatMapStrings (m: ''
        echo 'load fs0:\${m}.efi'
        echo 'echo ${m} %lasterror% >>a fs0:\status.txt'
      '') driver.modules}
      echo 'drivers >a fs0:\drivers.txt'
      echo 'reset -s'
    } > startup.nsh
    sed -i 's/$/\r/' startup.nsh

    mcopy -i esp.img ${shell}/shell.efi ::/EFI/BOOT/${bootFile}
    ${pkgs.lib.concatMapStrings (m: ''
      mcopy -i esp.img ${driver}/${m}.efi ::/
    '') driver.modules}
    mcopy -i esp.img startup.nsh ::/
    mcopy -i esp.img startup.nsh ::/EFI/BOOT/

    install -m0644 ${ovmf.variables} vars.fd
    timeout 900 ${qemu} \
      -accel tcg -m 2048 -nodefaults \
      -drive if=pflash,format=raw,readonly=on,file=${ovmf.firmware} \
      -drive if=pflash,format=raw,file=vars.fd \
      -display none -serial none \
      -drive file=esp.img,format=raw,if=virtio \
      -no-reboot

    mkdir -p "$out"
    mcopy -i esp.img ::/status.txt "$out/status.txt"
    mcopy -i esp.img ::/drivers.txt "$out/drivers.txt"
    # The shell writes UCS-2; dropping the NUL bytes leaves the ASCII.
    tr -d '\000\r' < "$out/status.txt" > status.txt
    tr -d '\000\r' < "$out/drivers.txt" > drivers.txt
    cat status.txt drivers.txt
    ${pkgs.lib.concatMapStrings (m: ''
      grep -q '^${m} 0x0' status.txt
      grep -qi '${m}' drivers.txt
    '') driver.modules}
    echo "${driver.pname} (${driver.targetArch}): every module loaded and registered a driver binding" \
      | tee "$out/report.txt"
  ''
