#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 SHARE_RAM[0x2000];
extern u8 ROM_Space[0x9C200];
extern u8 *mainCpu;
extern u8 *subCpu;
extern u8 *cpu2;
extern u8 *vromBase0;
extern u8 *vromBase1;
extern u8 *promBase;

void machineInit(void);
void loadCart(int, int);
void ejectCart(void);
void jackalMapper(int bank);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
