[org 0x7c00]            ; BIOS puts us here

KERNEL_OFFSET equ 0x1000 ; The memory address where we will load the C kernel

; 1. Save the boot drive
mov [BOOT_DRIVE], dl    ; BIOS stores our boot drive number in DL on startup

; 2. Set up the stack
mov bp, 0x9000          ; Set the base pointer safely above our code
mov sp, bp              ; Set the stack pointer to the base pointer

; 3. Load the kernel from disk
mov bx, KERNEL_OFFSET   ; BX = destination memory address for the kernel
mov ah, 0x02            ; BIOS function: Read disk sectors
mov al, 15              ; Number of sectors to read (adjust based on kernel size)
mov ch, 0               ; Cylinder 0
mov dh, 0               ; Head 0
mov cl, 2               ; Start reading at Sector 2 (Sector 1 is this bootloader)
mov dl, [BOOT_DRIVE]    ; The drive we are booting from
int 0x13                ; Execute BIOS disk interrupt

; 4. Jump to the C Kernel
jmp KERNEL_OFFSET       ; Hand over control to the memory address!

; Variables and padding
BOOT_DRIVE db 0
times 510-($-$$) db 0   ; Pad to 512 bytes
dw 0xaa55               ; Magic boot number
