#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

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
