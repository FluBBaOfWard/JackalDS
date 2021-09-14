#ifndef GFX_HEADER
#define GFX_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "K005849/K005849.h"

extern u8 g_flicker;
extern u8 g_twitch;
extern u8 g_scaling;
extern u8 g_gfxMask;

extern K005849 k005885_0;
extern K005849 k005885_1;
extern u8 k005885Palette[0x400];
extern u8 chipBank;
extern u16 EMUPALBUFF[0x200];

void gfxInit(void);
void vblIrqHandler(void);
void paletteInit(u8 gammaVal);
void paletteTxAll(void);
void refreshGfx(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GFX_HEADER
