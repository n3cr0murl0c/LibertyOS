# Step-by-Step Bootloader Tutorial

The bootloader simply asks the BIOS to read raw bytes from the disk (Sector 2 onward) and copy them into a specific address in RAM.

Once the bytes are in RAM, the bootloader uses a jmp (jump) instruction to point the CPU to that address.

## The 3 Core Responsibilities of boot.asm

1. _Set up a Stack:_ Before doing anything complex or calling functions, you need to tell the CPU where temporary memory (the stack) lives.

2. _Read the Disk:_ Use BIOS interrupts to load your compiled C kernel from the drive into memory.

3. _Pass Control:_ Jump to the exact memory address where you just loaded the kernel.

## Step 1: Install Dependencies

You need an assembler to convert code to machine language and an emulator to run it.

Windows/Linux/macOS: Install nasm (Netwide Assembler) and qemu (emulator).

## Step 2: Write the Boot Sector Code

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

## Step 3: Compile the Code

Open your terminal and compile the assembly file into a raw binary format.

```Bash
nasm -f bin boot.asm -o boot.bin
```

## Step 4: Emulate with QEMU

Boot your newly created binary file using the QEMU emulator.

```Bash
qemu-system-x86_64 -drive format=raw,file=boot.bin
```

A QEMU window will open, displaying the letter "H", proving your custom bootloader successfully executed on the bare-metal emulator.
