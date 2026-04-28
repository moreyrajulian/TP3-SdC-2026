# TP3 - Sistemas de Computación 2026  
## FCEFyN

### Integrantes
- José María Galoppo  
- Julián Moreyra  
- Pablo Díaz

### Repositorios

---

# 1. Introducción General



---

# 2. Organización de los Repositorios

El presente archivo README se encuentra replicado en cada uno de los repositorios asociados al trabajo práctico.  

Si bien la estructura general del documento se mantiene constante, es posible encontrar variaciones en:

- Ejemplos de código
- Scripts de compilación
- Casos de prueba específicos

Esto permite experimentar con distintas configuraciones manteniendo una base conceptual común.

---

# 3. Implementación Inicial del MBR

## 3.1 MBR mínimo funcional

En una primera etapa se desarrolló un **MBR mínimo funcional** utilizando la función `printf`.  

Este enfoque permitió generar una imagen binaria básica capaz de ser interpretada por el emulador **QEMU**, facilitando la validación inicial del entorno de ejecución.

![MBRbasic](img/MBRbasic.png)

---

# 4. Desarrollo en Lenguaje Ensamblador

En una segunda etapa se implementó un MBR más avanzado mediante **lenguaje ensamblador en modo real (16 bits)**.

Para ello se utilizó una cadena de herramientas compuesta por:

- Ensamblador
- Linker


## 4.1 Uso de la Interrupción 0x10

Se utilizó la interrupción:

`0x10`

correspondiente a los **servicios de video de la BIOS**, específicamente en modo texto.

Esto permitió la impresión directa de caracteres en pantalla sin depender de un sistema operativo.

---

## 4.2 Código Fuente del MBR

```asm
.code16
.global _start

_start:
    mov $msg, %si
    mov $0x0e, %ah

print_loop:
    lodsb
    or %al, %al
    jz halt
    int $0x10
    jmp print_loop

halt:
    hlt
    jmp halt

msg:
    .ascii "FFFFF  CCCCC  EEEEE  FFFFF  Y   Y  N   N\r\n"
    .ascii "F      C      E      F       Y Y   NN  N\r\n"
    .ascii "FFFF   C      EEEE   FFFF     Y    N N N\r\n"
    .ascii "F      C      E      F        Y    N  NN\r\n"
    .ascii "F      CCCCC  EEEEE  F        Y    N   N\r\n"
    .byte 0
```

---

## 4.3 Análisis del Código Ensamblador

Durante la inicialización:

- Se establece el registro `SI` apuntando al mensaje (`msg`)
- Se configura el registro `AH` con el valor `0x0E`, correspondiente a la función de teletipo de la BIOS

Esto permite preparar el entorno para imprimir caracteres en pantalla.

El bucle principal realiza las siguientes operaciones:

- `lodsb`  
  Carga un byte desde la dirección apuntada por `SI` en `AL`, incrementando automáticamente `SI`.

- `or %al, %al`  
  Permite verificar si el byte leído es nulo (fin de cadena).

- `jz halt`  
  Si se detecta el final del mensaje, se transfiere el control al estado de detención.

- `int $0x10`  
  Invoca la interrupción BIOS para imprimir el carácter almacenado en `AL`.

El ciclo continúa hasta encontrar el byte nulo final.

Cuando se alcanza el final del mensaje:

- `hlt` detiene la CPU
- Se ejecuta un bucle infinito para evitar comportamiento indefinido

![MBR2](img/MBR2.png)
---

# 7. Depuración y Análisis con GDB

Además del desarrollo del código ensamblador, se realizó un análisis detallado utilizando **GDB (GNU Debugger)**.

Comando usado
qemu-system-i386 -fda main.img -boot a -s -S -monitor stdio

Se abre puerto
Se conecta GDB por 1234

![GDB1](img/gdb1.png)
![GDB1](img/gdb2.png)

---

# 8. Verificación del Binario Generado

## 9.1 Comparación entre objdump y hd

Se realizó una comparación entre:

- `objdump`
- `hd` (hexdump)

Ubicación de la firma:
![firma](img/firma.png)

Ubicación de código en objdump y hd:
![objdump](img/objdump.png)
![hd](img/hd.png)

---



# 11. Apartado de respuestas

