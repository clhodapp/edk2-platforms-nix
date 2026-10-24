# Extras build status

Written by extras.yml for commit `0ad3620ce634`. Each feature is built against the edk2 stable tag as `extras.x86_64-linux.<name>` (edk2 202608) and against edk2 master as `extras.x86_64-linux.<name>-unstable` (edk2 0-unstable-20261020). A failure names the commit at which the attribute last built, and `extras-last-good.x86_64-linux.<attribute>` builds it from that commit.

| Feature | Stable | Unstable |
|---|---|---|
| `intel-acpi-debug-feature` | failure, never built | success |
| `intel-advanced-feature-pkg` | failure, never built | failure, never built |
| `intel-asf-feature` | failure, never built | success |
| `intel-beep-debug-feature` | failure, never built | success |
| `intel-ipmi-feature` | failure, never built | failure, never built |
| `intel-logo-feature` | failure, never built | success |
| `intel-network-feature` | failure, never built | success |
| `intel-platform-payload-feature` | failure, never built | success |
| `intel-post-code-debug-feature` | failure, never built | success |
| `intel-s3-feature` | failure, never built | success |
| `intel-smbios-feature` | failure, never built | success |
| `intel-spcr-feature` | failure, never built | success |
| `intel-template-feature` | failure, never built | success |
| `intel-usb3-debug-feature` | success | success |
| `intel-user-auth-feature` | failure, never built | failure, never built |
| `intel-virtual-keyboard-feature` | failure, never built | success |
