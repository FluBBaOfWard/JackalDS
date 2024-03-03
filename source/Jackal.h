#ifndef JACKAL_HEADER
#define JACKAL_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Shared/ArcadeRoms.h"

#define JK_GAME_COUNT (6)

extern const ArcadeRom jackalRoms[13];
extern const ArcadeRom jackalrRoms[13];
extern const ArcadeRom topgunrRoms[13];
extern const ArcadeRom jackaljRoms[13];
extern const ArcadeRom jackalblRoms[26];
extern const ArcadeRom topgunblRoms[26];

extern const ArcadeGame jackalGames[JK_GAME_COUNT];

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
