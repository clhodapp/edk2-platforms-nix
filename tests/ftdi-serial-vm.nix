# SPDX-License-Identifier: MIT
# Proves the FTDI driver binds a device and publishes Serial I/O: QEMU's
# `usb-serial` device emulates an FTDI FT232 behind an xHCI controller,
# the UEFI shell `load`s the driver and `connect -r`s so it binds, and
# the check requires a Serial I/O handle whose device path runs through
# a USB node to exist afterwards, which only the loaded driver can have
# produced (the firmware's own serial port, if any, sits on the platform
# bus). Whether a console then uses that port is the platform's
# ConIn/ConOut choice and not the driver's; nothing here exercises it.
{ pkgs, ftdiDriver }:
let
  aarch64 = ftdiDriver.stdenv.hostPlatform.isAarch64;
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
pkgs.runCommand "ftdi-serial-vm-check${pkgs.lib.optionalString aarch64 "-aarch64"}"
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

    # Echo on: the firmware's console also goes to the serial port,
    # which the run captures, so a hang shows where it stopped.
    cat > startup.nsh <<'NSH'
    @echo -on
    dh -p SerialIo >a fs0:\before.txt
    load fs0:\FtdiUsbSerialDxe.efi
    connect -r
    dh -p SerialIo -v >a fs0:\after.txt
    reset -s
    NSH
    sed -i 's/$/\r/' startup.nsh

    mcopy -i esp.img ${shell}/shell.efi ::/EFI/BOOT/${bootFile}
    mcopy -i esp.img ${ftdiDriver}/FtdiUsbSerialDxe.efi ::/
    mcopy -i esp.img startup.nsh ::/
    mcopy -i esp.img startup.nsh ::/EFI/BOOT/

    install -m0644 ${ovmf.variables} vars.fd
    timeout 600 ${qemu} \
      -accel tcg -m 2048 -nodefaults \
      -drive if=pflash,format=raw,readonly=on,file=${ovmf.firmware} \
      -drive if=pflash,format=raw,file=vars.fd \
      -display none -serial file:console.log \
      -drive file=esp.img,format=raw,if=virtio \
      -device qemu-xhci,id=xhci \
      -chardev file,id=ftdi,path=ftdi.out \
      -device usb-serial,bus=xhci.0,chardev=ftdi \
      -no-reboot || echo "qemu exited with status $?"

    mkdir -p "$out"
    cp console.log "$out/console.log"
    echo '--- firmware console ---'
    tr -d '\r' < console.log | tail -n 60
    mcopy -i esp.img ::/before.txt "$out/before.txt" || true
    mcopy -i esp.img ::/after.txt "$out/after.txt"
    # The shell writes UCS-2; dropping the NUL bytes leaves the ASCII.
    tr -d '\000\r' < "$out/after.txt" > after.txt
    cat after.txt
    # A Serial I/O handle on a USB device path: the FTDI driver's.
    grep -qi 'Usb' after.txt
    grep -qi 'SerialIo' after.txt
    echo "ftdi-usb-serial (${ftdiDriver.targetArch}): Serial I/O published on the emulated FT232" \
      | tee "$out/report.txt"
  ''
