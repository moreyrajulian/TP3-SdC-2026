#include <efi.h>
#include <efilib.h>

EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    InitializeLib(ImageHandle, SystemTable);
    Print(L"Hola mundo UEFI\r\n");    

    // Inyección de un software breakpoint (INT3)
    unsigned char code[] = { 0xCC };
    
    if (code[0] == 0xCC) {
        Print(L"Breakpoint estatico alcanzado.\r\n");
    }

    while (1);
    
    return EFI_SUCCESS;
}