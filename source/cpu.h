#ifndef CPU_HEADER
#define CPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "ARM6809/ARM6809.h"

extern u32 frameTotal;
extern u8 waitMaskIn;
extern u8 waitMaskOut;
extern ARM6809Core m6809CPU0;
extern ARM6809Core m6809CPU1;

void run(void);
void stepFrame(void);
void cpuInit(void);
void cpuReset(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CPU_HEADER
