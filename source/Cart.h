#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 g_ROM_Size;
extern u32 g_emuFlags;
extern u8 g_cartFlags;
extern u8 g_configSet;
extern u8 g_scalingSet;
extern u8 g_machineSet;
extern u8 g_machine;
extern u8 g_region;

extern u8 SHARE_RAM[0x2000];
extern u8 ROM_Space[0x9C200];

void machineInit(void);
void loadCart(int, int);
void ejectCart(void);
void jackalMapper(int bank);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
