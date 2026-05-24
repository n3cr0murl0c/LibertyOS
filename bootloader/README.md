# Step-by-Step Bootloader Tutorial

The bootloader simply asks the BIOS to read raw bytes from the disk (Sector 2 onward) and copy them into a specific address in RAM.

Once the bytes are in RAM, the bootloader uses a jmp (jump) instruction to point the CPU to that address.

## The 3 Core Responsibilities of boot.asm

1. _Set up a Stack:_ Before doing anything complex or calling functions, you need to tell the CPU where temporary memory (the stack) lives.

2. _Read the Disk:_ Use BIOS interrupts to load your compiled C kernel from the drive into memory.

3. _Pass Control:_ Jump to the exact memory address where you just loaded the kernel.

## Basic bootloader

### Step 1: Install Dependencies

You need an assembler to convert code to machine language and an emulator to run it.

Windows/Linux/macOS: Install nasm (Netwide Assembler) and qemu (emulator).

### Step 2: Write the Boot Sector Code

Create a file named boot.asm. This code tells the BIOS that the disk is bootable and halts the CPU.

```bash
; boot.asm
[org 0x7c00] ; BIOS puts us here it loads the bootloader at memory address 0x7c00
; 1. Save the boot drive
mov [BOOT_DRIVE], dl    ; BIOS stores our boot drive number in DL on startup
mov ah, 0x0e ; TTY mode for BIOS interrupt
mov al, 'H' ; Character to print
int 0x10 ; Call BIOS video interrupt

jmp $ ; Infinite loop to hang the system

times 510-($-$$) db 0 ; Pad the rest of the 512-byte sector with zeros
dw 0xaa55 ; Magic boot signature required by BIOS
```

### Step 3: Compile the Code

Open your terminal and compile the assembly file into a raw binary format.

```Bash
nasm -f bin boot.asm -o boot.bin
```

### Step 4: Emulate with QEMU

Boot your newly created binary file using the QEMU emulator.

```Bash
qemu-system-x86_64 -drive format=raw,file=boot.bin
```

A QEMU window will open, displaying the letter "H", proving your custom bootloader successfully executed on the bare-metal emulator.

## Bootloader Theory | Bootloader Requirements

- _Check for Disk Errors:_ The int 0x13 interrupt sets the Carry Flag (jc) if the disk read fails. A robust bootloader checks this flag and prints an error message instead of blindly jumping to empty memory.

- _Define Segment Registers:_ Always explicitly set your ds, es, and ss (Data, Extra, and Stack segments) to zero at the start. You cannot trust the BIOS to initialize them predictably.

- _Keep it Under 512 Bytes:_ The BIOS only loads the first 512 bytes. If your bootloader code gets too big, it will silently fail to execute the overflowing instructions.

- _Jump 16->32-64:_ Modern x86_64 systems still boot in 16-bit mode for legacy compatibility and must traverse a specific path:
  16-bit -> 32-bit -> 64-bit.

  To transition from 32-bit state into 64-bit Long Mode, you must complete these additional steps:
  1. _Set up Paging:_ 64-bit mode strictly requires memory paging. You must build Page Map Level 4 (_PML4_), Page Directory Pointer, Page Directory, and Page Tables in memory, and point the cr3 register to your PML4 table.

  2. _Enable PAE:_ Set the Physical Address Extension flag in the cr4 register.

  3. _Enable Long Mode:_ Set the Long Mode Enable (LME) bit in the EFER (Extended Feature Enable Register) Model Specific Register.

  4. _Enable Paging:_ Set the paging bit in the cr0 register.

  5. _Load a 64-bit GDT:_ Create a new GDT specifically tailored for 64-bit segments and load it.

  6. _Far Jump again:_ Execute another far jump into the 64-bit code segment.
