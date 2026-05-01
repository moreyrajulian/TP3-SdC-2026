.code16             
.global _start

_start:
    # 1. Deshabilitar interrupciones
    cli             

    # 2. Cargar el registro GDTR con la dirección y tamaño de nuestra GDT
    lgdt gdt_descriptor

    # 3. Habilitar A20 
    inb $0x92, %al
    orb $0b00000010, %al
    outb %al, $0x92

    # 4. Fijar el bit más bajo del CR0 (PE - Protection Enable) en 1
    movl %cr0, %eax
    orl $0x1, %eax
    movl %eax, %cr0

    # 5. Salto largo (Far Jump) para limpiar el pipeline y cargar CS
    ljmp $0x08, $protected_mode

.code32             
protected_mode:
    # 6. Configurar el resto de los registros de segmento con el selector de datos
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss

    movl $0x90000, %esp # Apuntamos el stack a una dirección segura (dentro de nuestro segmento de datos)

     # --- PRUEBA DE ESCRITURA ---
    movl $0x00000000, %ebx
    movb $0xAA, (%ebx)      # ¡Esto va a causar Triple Fault si el segmento de datos es solo de lectura!

    movl $0xA8000, %edi
    movl $80*25, %ecx
    movw $0x0720, %ax

    clear_screen:
        movw %ax, (%edi)
        addl $2, %edi
        loop clear_screen

    movl $0x2F4B2F4F, 0xA8000   ; # "OK" en pantalla
    jmp .

# ---------------------------------------------------------
# DEFINICIÓN DE LA GDT
# ---------------------------------------------------------
.align 8
gdt_start:
    # 1. Descriptor Nulo (obligatorio, 8 bytes de ceros)
    .quad 0x0000000000000000

    # 2. Descriptor de Código (Selector 0x08)
    # Base: 0x00000000, Límite: 0xFFFFF, Granularidad: 4KB, Ejecución/Lectura
    .word 0xFFFF        # Limit 0:15
    .word 0x0000        # Base 0:15
    .byte 0x00          # Base 16:23
    .byte 0b10011010    # Presente, Privilegio 0 (Ring 0), Tipo: Código Ejecución/Lectura
    .byte 0b11001111    # Granularidad (4KB), Tamaño 32-bit, Limit 16:19
    .byte 0x00          # Base 24:31

    # 3. Descriptor de Datos DIFERENCIADO (Selector 0x10)
    # Base: 0x00010000, Límite: 0xFFFFF, Granularidad: 4KB, Lectura/Escritura
    .word 0xFFFF        # Limit 0:15
    .word 0x0000        # Base 0:15 
    .byte 0x01          # Base 16:23 -> BASE TOTAL: 0x00010000
    .byte 0b10010000    # Presente, Privilegio 0 (Ring 0), Tipo: Datos SOLO LECTURA (.byte 0b10010010 sería lectura/escritura)
    .byte 0b11001111    # Granularidad (4KB), Tamaño 32-bit, Limit 16:19
    .byte 0x00          # Base 24:31
gdt_end:

gdt_descriptor:
    .word gdt_end - gdt_start - 1   # Tamaño de la GDT
    .long gdt_start                 # Dirección base de la GDT
