# SPDX-License-Identifier: MIT
# Proves Ext4Dxe works end to end in a VM against a filesystem made by the
# formatter a NixOS installer uses. The firmware boots the UEFI shell from
# a FAT disk; a second disk carries an ext4 filesystem produced by nixpkgs'
# mkfs.ext4 with stock defaults (the tool disko invokes for
# `format = "ext4"`, so the feature set — 64bit, extents, flex_bg,
# metadata_csum[_seed], … — is the one the driver meets in the field),
# populated offline via mke2fs -d. startup.nsh loads Ext4Dxe.efi,
# reconnects handles so the driver binds the ext4 BlockIo, remaps, and
# copies a payload from the ext4 volume back onto the FAT disk: a
# multi-block file (exercising extent reads) plus a file in a nested
# directory (exercising directory lookup). Verification extracts the
# copies with mtools and compares them byte-for-byte against the
# originals.
#
# The firmware, shell, boot file name, and machine follow the driver's
# architecture: OVMF on QEMU's q35 for x86-64; nixpkgs' cross-built
# ArmVirtQemu, the AArch64 shell, and QEMU's `virt` machine for AArch64.
{ pkgs, ext4Dxe }:
let
  aarch64 = ext4Dxe.stdenv.hostPlatform.isAarch64;
  # Firmware and shell for the driver's own architecture: the host's
  # packages for x86-64, the cross set's for AArch64.
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
pkgs.runCommand "ext4-dxe-vm-check${pkgs.lib.optionalString aarch64 "-aarch64"}"
  {
    nativeBuildInputs = [
      # qemu_test builds only the host's system emulator; the AArch64 run
      # needs the full package.
      (if aarch64 then pkgs.qemu else pkgs.qemu_test)
      pkgs.mtools
      pkgs.dosfstools
      pkgs.e2fsprogs
    ];
  }
  ''
    # --- ext4 disk: stock format, known payload ------------------------------
    mkdir -p root/nested/dir
    # Multi-block deterministic payload (1 MiB of numbered lines).
    seq -f 'ext4-dxe payload line %012.0f' 1 25000 > root/payload.txt
    echo 'ext4-dxe nested marker' > root/nested/dir/marker.txt
    truncate -s 64M ext4.img
    mkfs.ext4 -q -d root ext4.img

    # --- FAT disk: shell as default boot loader + driver + script -----------
    truncate -s 16M esp.img
    mkfs.vfat esp.img
    mmd -i esp.img ::/EFI ::/EFI/BOOT

    cat > startup.nsh <<'NSH'
    @echo -off
    load fs0:\Ext4Dxe.efi
    connect -r
    map -r
    map >a fs0:\map.txt
    cp fs1:\payload.txt fs0:\payload.out
    cp fs1:\nested\dir\marker.txt fs0:\marker.out
    reset -s
    NSH
    sed -i 's/$/\r/' startup.nsh

    mcopy -i esp.img ${shell}/shell.efi ::/EFI/BOOT/${bootFile}
    mcopy -i esp.img ${ext4Dxe}/Ext4Dxe.efi ::/
    mcopy -i esp.img startup.nsh ::/
    mcopy -i esp.img startup.nsh ::/EFI/BOOT/

    # --- boot the firmware; the script shuts the VM down when done ----------
    install -m0644 ${ovmf.variables} vars.fd

    timeout 900 ${qemu} \
      -accel tcg -m 2048 -nodefaults \
      -drive if=pflash,format=raw,readonly=on,file=${ovmf.firmware} \
      -drive if=pflash,format=raw,file=vars.fd \
      -display none -serial none \
      -drive file=esp.img,format=raw,if=virtio \
      -drive file=ext4.img,format=raw,if=virtio \
      -no-reboot

    # --- extract the shell's evidence and verify ----------------------------
    mkdir -p "$out"
    mcopy -i esp.img ::/map.txt "$out/map.txt" || true
    mcopy -i esp.img ::/payload.out payload.out
    mcopy -i esp.img ::/marker.out marker.out
    cmp root/payload.txt payload.out
    cmp root/nested/dir/marker.txt marker.out
    cp payload.out marker.out "$out/"
    echo "ext4-dxe (${ext4Dxe.targetArch}): payload + nested marker read back byte-identical" \
      | tee "$out/report.txt"
  ''
