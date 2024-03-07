#ifdef __arm__

#include "Shared/EmuSettings.h"
#include "ARM6809/ARM6809mac.h"
#include "K005849/K005849.i"

	.global machineInit
	.global loadCart
	.global jackalMapper
	.global emuFlags
	.global romNum
//	.global scaling
	.global cartFlags
	.global romStart
	.global mainCpu
	.global subCpu
	.global cpu2
	.global vromBase0
	.global vromBase1
	.global promBase

	.global SHARED_RAM
	.global ROM_Space



	.syntax unified
	.arm

	.section .rodata
	.align 2

rawRom:
/*
	.incbin "jackal/631_v02.15d"
	.incbin "jackal/631_v03.16d"
	.incbin "jackal/631_t01.11d"
	.incbin "jackal/631t04.7h"
	.incbin "jackal/631t05.8h"
	.incbin "jackal/631t06.12h"
	.incbin "jackal/631t07.13h"
	.incbin "jackal/631r08.9h"
	.incbin "jackal/631r09.14h"
*/
/*
	.incbin "jackal/560-k03.13c"
	.incbin "jackal/560-k02.12c"
	.incbin "jackal/560-j01.10c"
	.incbin "jackal/560-j06.8f"
	.incbin "jackal/560-j05.7f"
	.incbin "jackal/560-k07.9f"
	.incbin "jackal/560-k04.6f"
	.incbin "jackal/03f_h08.bin"
	.incbin "jackal/04f_h09.bin"
*/
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	bl gfxInit
//	bl ioInit
	bl soundInit
	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	mov r11,r0
	str r0,romNum
	str r1,emuFlags

//	ldr r7,=rawRom
//	ldr r7,=ROM_Space
//	str r7,romStart				;@ Set rom base
//	add r0,r7,#0x1C000			;@ 0x14000
//	str r0,vromBase0			;@ Gfx1
//	add r0,r0,#0x40000
//	str r0,vromBase1			;@ Gfx2
//	add r0,r0,#0x40000
//	str r0,promBase				;@ Colour prom

;@----------------------------------------------------------------------------

	bl doCpuMappingJackalMain
	bl doCpuMappingJackalSub

	mov r0,r11					;@ Set r0 to gameNr
	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
jackalMapper:				;@ Switch bank for 0x4000-0xBFFF, 4 banks.
	.type   jackalMapper STT_FUNC
;@----------------------------------------------------------------------------
	and r0,r0,#0x20
	ldr r1,=mainCpu
	ldr r1,[r1]
	add r1,r1,r0,lsl#10
	sub r1,r1,#0x4000
	ldr r2,=m6809CPU0
	str r1,[r2,#m6809MemTbl+4*2]
	str r1,[r2,#m6809MemTbl+4*3]
	str r1,[r2,#m6809MemTbl+4*4]
	str r1,[r2,#m6809MemTbl+4*5]
	bx lr
;@----------------------------------------------------------------------------
doCpuMappingJackalMain:
;@----------------------------------------------------------------------------
	adr r2,JackalMapping
	b do6809MainCpuMapping
;@----------------------------------------------------------------------------
doCpuMappingJackalSub:
;@----------------------------------------------------------------------------
	adr r2,JackalSubMapping
	ldr r0,=m6809CPU1
	ldr r1,subCpu
	b m6809Mapper
;@----------------------------------------------------------------------------
JackalMapping:						;@ Jackal
	.long SHARED_RAM, JackalIO_R, JackalIO_W					;@ IO
	.long GFX_RAM0, k005885Ram_0R, k005885Ram_0W				;@ Graphic
	.long 0, mem6809R2, rom_W									;@ ROM
	.long 1, mem6809R3, rom_W									;@ ROM
	.long 2, mem6809R4, rom_W									;@ ROM
	.long 3, mem6809R5, rom_W									;@ ROM
	.long 8, mem6809R6, rom_W									;@ ROM
	.long 9, mem6809R7, rom_W									;@ ROM
;@----------------------------------------------------------------------------
JackalSubMapping:					;@ Jackal sub cpu
	.long emptySpace, empty_R, empty_W							;@ Empty
	.long emptySpace, YM0_R, YM0_W								;@ Sound
	.long k005885Palette, paletteRead, paletteWrite				;@ Palette
	.long SHARED_RAM, mem6809R3, sharedRAM_W					;@ RAM
	.long 0, mem6809R4, rom_W									;@ ROM
	.long 1, mem6809R5, rom_W									;@ ROM
	.long 2, mem6809R6, rom_W									;@ ROM
	.long 3, mem6809R7, rom_W									;@ ROM

;@----------------------------------------------------------------------------
do6809MainCpuMapping:
;@----------------------------------------------------------------------------
	ldr r0,=m6809CPU0
	ldr r1,mainCpu
;@----------------------------------------------------------------------------
m6809Mapper:		;@ Rom paging.. r0=cpuptr, r1=romBase, r2=mapping table.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}

	add r7,r0,#m6809MemTbl
	add r8,r0,#m6809ReadTbl
	add lr,r0,#m6809WriteTbl

	mov r6,#8
m6809M2Loop:
	ldmia r2!,{r3-r5}
	cmp r3,#0x100
	addmi r3,r1,r3,lsl#13
	rsb r0,r6,#8
	sub r3,r3,r0,lsl#13

	str r3,[r7],#4
	str r4,[r8],#4
	str r5,[lr],#4
	subs r6,r6,#1
	bne m6809M2Loop
;@------------------------------------------
m6809Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
//	reEncodePC
	ldmfd sp!,{r4-r8,lr}
	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romnumber
romInfo:						;@ Keep emuflags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ emuflags      (label this so Gui.c can take a peek) see EmuSettings.h for bitfields
//scaling:
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartflags
	.space 3

romStart:
mainCpu:
	.long 0
subCpu:
cpu2:
	.long 0
vromBase0:
	.long 0
vromBase1:
	.long 0
promBase:
	.long 0

	.section .bss
	.align 2
SHARED_RAM:
	.space 0x2000
ROM_Space:
	.space 0x9C200
emptySpace:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
