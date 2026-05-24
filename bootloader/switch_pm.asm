switch_to_pm:
    cli                     ; 1. Clear/Disable interrupts
    lgdt [gdt_descriptor]   ; 2. Load the Global Descriptor Table

    mov eax, cr0            ; 3. Move CR0 register to EAX
    or eax, 0x1             ; 4. Set the first bit (Protection Enable bit) to 1
    mov cr0, eax            ; 5. Move updated value back to CR0

    jmp CODE_SEG:init_pm    ; 6. Perform a "far jump" to 32-bit code

[bits 32]
init_pm:
    mov ax, DATA_SEG        ; 7. Update all segment registers to the new 32-bit Data Segment
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000        ; 8. Update the stack pointer to the top of free memory
    mov esp, ebp

    ; The CPU is now in 32-bit Protected Mode.
    ; You can safely call your C Kernel from here.
