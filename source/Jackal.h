#ifndef JACKAL_HEADER
#define JACKAL_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Shared/ArcadeRoms.h"

#define GAME_COUNT (6)

extern const ArcadeGame games[GAME_COUNT];

/// This runs all save state functions for each chip.
int packState(void *statePtr);

/// This runs all load state functions for each chip.
void unpackState(const void *statePtr);

/// Gets the total state size in bytes.
int getStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // JACKAL_HEADER
