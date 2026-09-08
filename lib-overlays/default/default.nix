# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    ext4-dxe = prev.ext4-dxe or { };
  };

}
