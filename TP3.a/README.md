# TP3 - Sistemas de Computación 2026  
## FCEFyN

### Integrantes
- José María Galoppo  
- Julián Moreyra  
- Pablo Díaz

---

# 1. Introducción General


# 2. Organización de los Repositorios

El presente archivo `README` se encuentra replicado en cada uno de los repositorios asociados al trabajo práctico. En particular, en este documento se explica una extensión del TP3 dedicada exclusivamente a la interfaz UEFI.

Si bien la estructura general de la documentación se mantiene constante, es posible encontrar variaciones en:

- Ejemplos de código.
- Scripts de compilación.
- Casos de prueba específicos.

Esta modularidad permite experimentar con distintas configuraciones manteniendo una base conceptual común en todos los repositorios.

# 3. Exploración del entorno UEFI y la Shell

## 3.1 Arranque en el entorno virtual y exploración de Dispositivos (Handles y Protocolos)

![shellUefi](img/shellUEFI.png)
*Figura 1: Captura de la shell de UEFI mostrando la inicialización del entorno y el mapeo de los dispositivos disponibles.*

**Pregunta de Razonamiento 1: Al ejecutar el comando `map` y `dh`, vemos protocolos e identificadores en lugar de puertos de hardware fijos. ¿Cuál es la ventaja de seguridad y compatibilidad de este modelo frente al antiguo BIOS?**

Este paradigma provee una abstracción total del hardware subyacente. Permite utilizar el mismo firmware UEFI para interactuar con arquitecturas y dispositivos de hardware sumamente diversos (discos, memoria, E/S) mediante interfaces estandarizadas (protocolos), en lugar de depender de interrupciones o puertos fijos. Desde una perspectiva de seguridad, esto garantiza un acceso mucho más controlado y estructurado al hardware, mitigando errores críticos y accesos arbitrarios peligrosos. Sin embargo, al ser UEFI una especificación mucho más robusta y compleja, la superficie de ataque potencial se ve lógicamente ampliada.

## 3.2 Análisis de Variables Globales (NVRAM)

**Pregunta de Razonamiento 2: Observando las variables `Boot####` y `BootOrder`, ¿cómo determina el Boot Manager la secuencia de arranque?**

La prioridad de arranque queda estrictamente definida por el arreglo de identificadores almacenado en la variable `BootOrder` dentro de la NVRAM. El *Boot Device Selector* (BDS) lee esta secuencia y procede a buscar la entrada `Boot####` correspondiente (por ejemplo, `Boot0001`). Finalmente, el firmware lee la ruta contenida en dicha variable, la cual apunta directamente a la ubicación del ejecutable EFI (`.efi`) en la partición del sistema, iniciando así su carga y ejecución.

![dmpstore](img/dmpstore.png)
*Figura 2: Salida del comando `dmpstore`, detallando el volcado de las variables de entorno almacenadas en la NVRAM.*

![setVariable](img/setVariable.png)
*Figura 3: Ejecución y manipulación de variables en la shell, evidenciando cómo se gestionan los parámetros de configuración del sistema.*

## 3.3 Footprinting de Memoria y Hardware

![memmap](img/memmap.png)
*Figura 4: Mapa de memoria (`memmap`) reportado por UEFI, donde se describen las distintas regiones físicas, su tipo y los atributos de acceso asignados.*

![pci](img/pci.png)

**Pregunta de Razonamiento 3: En el mapa de memoria (`memmap`), existen regiones marcadas como `RuntimeServicesCode`. ¿Por qué estas áreas son un objetivo principal para los desarrolladores de malware (Bootkits)?**

Estas regiones son críticas porque alojan servicios que persisten en memoria incluso después de que el sistema operativo toma el control (*ExitBootServices*). Al ejecutarse a nivel de firmware y con los máximos privilegios de la arquitectura, representan un vector ideal para la persistencia. Un atacante que logre inyectar código allí podría instalar *hooks* en las llamadas del firmware, alterar variables críticas (como desactivar `SecureBoot` o modificar `BootOrder`), y manipular subrepticiamente el arranque o los mecanismos de seguridad del sistema operativo antes de que este inicie.

# 4. Desarrollo, compilación y análisis de seguridad

## 4.1 Desarrollo de la Aplicación

**Pregunta de Razonamiento 4: ¿Por qué utilizamos SystemTable->ConOut->OutputString en lugar de la función printf de C?**

Utilizamos este protocolo ya que nos encontramos en un escenario pre-SO, es decir, que no tenemos acceso a la libreria estandar de C para poder hacer uso de funciones importadas.

## 4.2 Análisis de Metadatos y Decompilación

Una vez generado el binario nativo en formato estándar PE/COFF, lo que buscamos es hacer el proceso inverso: analizar un archivo compilado. 
Para ello realizamos algunos pasos:
- Primero ejecutamos el comando `file aplicacion.efi` para leer los primeros bytes del archivo y así poder determinar su verdadero tipo analizando su estructura interna. A continuación confirmamos que el archivo ``aplicacion.efi`` es un ejecutable PE32+.
![file](/TP3.a/img/file.png)

- Luego seguimos ejecutando el comando ``readelf -h aplicacion.efi`` que nos muestra las cabeceras del formato del archivo objeto, esto para poder verificar la arquitectura. Como observamos en la imagen el comando nos dice que el archivo ``aplicacion.efi`` no es un archivo ELF, esto ya que el comando se encarga de leer cabeceras de archivos en ese formato pero el archivo pasado utiliza el formato estándar PE/COFF. Entonces al intentar buscar y leer los magic bytes se encuentra con otra firma diferente a la de un archivo Linux.
![readelf](/TP3.a/img/readelf.png)
Consideramos que si queremos ver las cabeceras del archivo ``.efi`` debemos utilizar el comando ``objdump`` que es la herramienta para leer binarios de múltiples formatos.
![objdump](/TP3.a/img/objdump.png)

- Por último haremos uso de la herramienta Ghidra que es una plataforma de Ingeniería Inversa de Software, su función principal es realizar el **desensamblado** del código máquina a Assembler puro y la **descompilación** que trata de reconstruir un pseudocódigo de C a partir del Assembler obtenido. Esto es muy útil a la hora de analizar firmware sin tener el código fuente original.

**Pregunta de Razonamiento 5: En el pseudocódigo de Ghidra, la condición 0xCC suele aparecer como -52. ¿A qué se debe este fenómeno y por qué importa en ciberseguridad?**

Este fenómeno se debe a como se interpretan los tipos de datos entre el código original y el descompilador. Este último suele interpretar por defecto el tipo de dato `char` como un entero de 8 bits con signo, como el hexa `0xCC` equivale a `11001100` y como el MSB es 1 el sistema aplica la regla del complemento a dos, al calcular esto con signo el valor decimal original de 204 se desborda y equivale a -52. Esto impacta en el ámbito de la ciberseguridad ya que el valor `0xCC` corresponde al opcode en ensamblador x86 para la instrucción `INT3` utilizada comunmente por atacantes para inyectar breakpoints de software o trampas a nivel de firmware.

Por ello es muy importante no confiar ciegamente en el pseudocodigo y crear alguna regla para detectar `204` o `-52` por ejemplo. Para realizar una detección fuerte debemos analizar el binario directamente a nivel de los bytes crudos.

A continuación veremos el pseudocódigo que nos otorga Ghidra, notaremos que no se observa los valores esperados ya que las versiones modernas de Ghidra realizan una eliminación del código muerto y no nos muestra el if comparando el hexa usado como variable pero que claramente ingresa e imprime el mensaje.

![ghidra](/TP3.a/img/ghidra.png)

# 5. Ejecución en Hardware Físico (Bare Metal)

Lo que haremos a continuación será trasladar el binario compilado a una computadora real sorteando las restricciones del Secure Boot. Para ello utilizaremos un pendrive como medio de arranque, se tuvo que destruir la tabla de particiones existentes del mismo y crear una única partición limpia formateada en **FAT32**, luego se creó la ruta de directorios ``/EFI/BOOT/`` y se copió la UEFI Shell renombrada como ``BOOTX64.EFI``:

![pendrive](/TP3.a/img/pendrive.png)

Se utilizó una aplicación en C distinta a la que se utilizó en el anterior punto ya que fallaba a la hora de mostrar los mensajes por pantalla. Para ello se implementó un ciclo ``while(1)``, esto para impedir que el programa ejecute el ``return EFI_SUCCESS`` ya que este terminaba tán rapido que le devolvía el control a la UEFI Shell al instante y no permitía ver los mensajes.

Luego en vez de acceder a la memoria con el protocolo ``SystemTable->ConOut->OutputString(...)`` utilizamos ``Print()``, esto funciona como un wrapper robusto que nos provee la librería ``gnu-efi``, por debajo hace lo mismo pero maneja mejor los puntos y tipos de caracteres.

Posterior a esto se accedió al menú de configuración de firmware, se configuró una contraseña de supervisor temporal para desbloquear los parámetros de seguridad y se desactivó el **Secure Boot**. Esto ya que nuestro binario ``aplicacion.efi`` fue compilado localmente y no tiene firma digital, el firmware lo considera una amenaza y bloquea su ejecución. 

Finalmente desde el menú de arranque se seleccionó el dispositivo USB. Al cargar la UEFI Shell se ejecutó el comando ``FSO:`` para cambiar al sistema de archivos del pendrive y ejecutar la aplicación que muestra por pantalla los mensajes **"Hola mundo UEFI"** y **"Breakpoint estatico avanzado"**.

A continuación veremos el resultado:

![baremetal](/TP3.a/img/baremetal.png)



