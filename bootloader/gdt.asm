; gdt.asm
gdt_start:
    dq 0x0                  ; Null descriptor (8 bytes of zeros) Required By Intel

gdt_code:                   ; Code segment descriptor
    dw 0xffff, 0x0          ; Limit (bits 0-15), Base (bits 0-15)
    db 0x0, 0x9a, 0xcf, 0x0 ; Base (16-23), Access byte, Flags, Base (24-31)

gdt_data:                   ; Data segment descriptor
    dw 0xffff, 0x0          ; Limit (bits 0-15), Base (bits 0-15)
    db 0x0, 0x92, 0xcf, 0x0 ; Base (16-23), Access byte, Flags, Base (24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of the GDT
    dd gdt_start               ; Start address of the GDT

; Define constants for the segment offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
