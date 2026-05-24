# LibertyOS

> A hybrid OS built on the Linux kernel that natively hosts Win32 applications, Windows drivers, and kernel-level anti-cheat — **without** visible virtualization or emulation layers.

## Thesis

Run demanding Windows games (GTA 6 class) on lightweight or aging hardware while keeping Linux's security posture and shedding Windows' malware surface. No Wine prefix friction. No "compatibility layer" UX. `.exe` runs as a first-class LibertyOS process.

## Architecture at a glance

```text
┌─────────────────────────────────────────────────────────────┐
│  Shell (GUI/CLI) — native LibertyOS desktop                 │
├─────────────────────────────────────────────────────────────┤
│  Win32 Userspace Runtime (Wine fork, hardened)              │
│  ─ binfmt_misc PE loader: .exe → native process             │
├─────────────────────────────────────────────────────────────┤
│  NT Syscall Personality Layer    │  POSIX syscalls          │
│  ─ Object Manager → fd/inode map │  ─ standard Linux ABI    │
│  ─ Handle table translation      │                          │
│  ─ Security descriptor → LSM     │                          │
├─────────────────────────────────────────────────────────────┤
│  Graphics: Vulkan (native)  │  DX12 → VKD3D-Proton 3.0      │
├─────────────────────────────────────────────────────────────┤
│  Hardened Linux Kernel (LSM, BORE scheduler, io_uring)      │
│  ─ eBPF syscall interception                                │
├─────────────────────────────────────────────────────────────┤
│  VT-x Micro-Hypervisor                                      │
│  ─ EPT-isolated compartments for WDM anti-cheat drivers     │
│  ─ Inverts AC's own VMX technique against the AC itself     │
├─────────────────────────────────────────────────────────────┤
│  Hardware (TPM-backed attestation for remote trust)         │
└─────────────────────────────────────────────────────────────┘
```

## Phased build order

| Phase | Component                                   | Goal                                                                                                                    |
| ----- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| 1     | Hardened Linux kernel foundation            | Baseline: LSM stack, BORE scheduler, io_uring, locked-down attack surface                                               |
| 2     | NT syscall personality module               | Map NT Executive semantics (Object Manager, handle tables, security descriptors) onto Linux primitives                  |
| 3     | Win32 userspace runtime                     | Forked Wine, integrated with `binfmt_misc` PE loader — `.exe` launches as a native process                              |
| 4     | VT-x driver compartments                    | Micro-hypervisor with EPT isolation; host Windows kernel drivers safely                                                 |
| 5a    | Anti-cheat: BattlEye Linux opt-in           | Pragmatic near-term path — use the vendor-supported Linux build                                                         |
| 5b    | Anti-cheat: WDM hosting in VT-x compartment | Long-term path — run `BEDaisy.sys` & co. in VMX non-root Ring-0 with EPT blocking access to LibertyOS kernel structures |
| 6     | TPM-backed remote attestation               | Architecturally sound long-term anti-cheat trust model                                                                  |

## Key design decisions

**Graphics — Vulkan native, DX12 transparent.** Vulkan is the system API: open standard, lower CPU overhead, better behavior on weaker hardware. DX12 titles route through VKD3D-Proton 3.0 with no user-visible step.

**Anti-cheat sandboxing — invert their own weapon.** Modern kernel anti-cheats use VT-x to inspect the system from below. LibertyOS uses the same technique on _them_: the AC driver runs in a VMX non-root Ring-0 compartment with EPT mappings that allow read access to game process memory but block access to LibertyOS kernel structures. The AC sees what it needs to function; it cannot see (or compromise) the host kernel.

**`.exe` execution — no visible compat layer.** `binfmt_misc` registers a PE handler that hands off to the Win32 runtime. From the user's perspective, double-clicking `game.exe` is identical to launching a native binary. No `wine game.exe`. No prefix wizardry.

**Syscall interception — eBPF-assisted.** eBPF programs sit on the syscall path to route NT-style calls into the personality layer without a heavyweight ptrace-based interposer.

## The hard problem: NT ↔ Linux structural mismatch

The single most foundational challenge. NT and Linux disagree at the primitive level:

| NT                                           | Linux                                                 |
| -------------------------------------------- | ----------------------------------------------------- |
| Object Manager (unified namespace)           | VFS + procfs + sysfs + ...                            |
| Handle table (per-process opaque handles)    | File descriptor table (integers indexing struct file) |
| Security descriptors (ACL-based, per-object) | UID/GID + mode bits + LSM hooks                       |
| Section objects (mappable named memory)      | shm + mmap                                            |
| APCs, IRQLs, IRPs                            | softirqs, tasklets, workqueues                        |

The NT syscall personality layer is the bridge. It's not a translation table — it's a semantic adapter that has to preserve enough NT behavior that Win32 software and Windows kernel drivers cannot tell the difference.

## Prior art being studied

- **ReactOS** — open-source NT reimplementation; reference for NT object/handle semantics
- **Windows Research Kernel** — authoritative reference for NT Executive internals
- **LWN seccomp / PROT_NOSYSCALL proposals** — relevant patterns for syscall filtering and dispatch

## Current status

Research and architecture phase. No deadline pressure — correctness and depth over speed. The bootloader work (see [`bootloader/README.md`](./bootloader/README.md)) is foundational practice for understanding the boot path LibertyOS will eventually own end-to-end.

## Glossary

`SSDT` System Service Descriptor Table · `NT Executive` NT kernel-mode core · `WDM` Windows Driver Model · `DSE` Driver Signature Enforcement · `EPT` Extended Page Tables (Intel VT-x) · `VMX root/non-root` hypervisor vs. guest CPU mode · `VTL 0/1` Virtual Trust Levels (Hyper-V VBS concept) · `pico processes` minimal NT processes (used by WSL1) · `binfmt_misc` Linux mechanism to register interpreters for arbitrary binary formats · `io_uring` async I/O syscall interface · `BORE` Burst-Oriented Response Enhancer scheduler · `LSM` Linux Security Module framework · `VKD3D-Proton` DX12→Vulkan translation layer · `eBPF` in-kernel programmable VM · `BEDaisy.sys` BattlEye kernel driver
