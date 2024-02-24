#ifdef __arm__

#include "Shared/EmuSettings.h"
#include "ARM6809/ARM6809mac.h"
#include "K005849/K005849.i"

	.global machineInit
	.global loadCart
	.global m6809Mapper
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

	.global SHARE_RAM
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
	ldr r7,=ROM_Space			;@ r7=rombase til end of loadcart so DON'T FUCK IT UP
//	str r7,romStart				;@ Set rom base
//	add r0,r7,#0x1C000			;@ 0x14000
//	str r0,vromBase0			;@ Gfx1
//	add r0,r0,#0x40000
//	str r0,vromBase1			;@ Gfx2
//	add r0,r0,#0x40000
//	str r0,promBase				;@ Colour prom

;@----------------------------------------------------------------------------
	ldr r4,=MEMMAPTBL_
	ldr r5,=RDMEMTBL_
	ldr r6,=WRMEMTBL_

	mov r0,#0
	ldr r2,=mem6809R0
	ldr r3,=rom_W
tbLoop1:
	add r1,r7,r0,lsl#13
	bl initMappingPage
	add r0,r0,#1
	cmp r0,#0x88
	bne tbLoop1

	ldr r1,=emptySpace
	ldr r2,=empty_R
	ldr r3,=empty_W
tbLoop3:
	bl initMappingPage
	add r0,r0,#1
	cmp r0,#0x100
	bne tbLoop3


	mov r0,#0xF8				;@ RAM
	ldr r1,=SHARE_RAM
	ldr r2,=mem6809R0
	ldr r3,=ram_W
	bl initMappingPage

	mov r0,#0xFC				;@ IO
	ldr r1,=emptySpace
	ldr r2,=YM0_R
	ldr r3,=YM0_W
	bl initMappingPage

	mov r0,#0xFD				;@ Palette RAM
	ldr r1,=k005885Palette
	ldr r2,=paletteRead
	ldr r3,=paletteWrite
	bl initMappingPage

	mov r0,#0xFE				;@ GFX RAM
	ldr r1,=emuRAM0
	ldr r2,=k005885Ram_0R
	ldr r3,=k005885Ram_0W
	bl initMappingPage

	mov r0,#0xFF				;@ IO
	ldr r1,=SHARE_RAM
	ldr r2,=IO_R
	ldr r3,=IO_W
	bl initMappingPage

	mov r0,r11					;@ Set r0 to gameNr
	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
initMappingPage:	;@ r0=page, r1=mem, r2=rdMem, r3=wrMem
;@----------------------------------------------------------------------------
	str r1,[r4,r0,lsl#2]
	str r2,[r5,r0,lsl#2]
	str r3,[r6,r0,lsl#2]
	bx lr

;@----------------------------------------------------------------------------
//	.section itcm
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
jackalMapper:				;@ Switch bank for 0x4000-0xBFFF, 2 banks.
	.type   jackalMapper STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,m6809ptr,lr}
	ldr m6809ptr,=m6809CPU0

	and r4,r0,#0x20
	mov r4,r4,lsr#3

	mov r1,r4
	mov r0,#0x04
	bl m6809Mapper

	add r1,r4,#1
	mov r0,#0x08
	bl m6809Mapper

	add r1,r4,#2
	mov r0,#0x10
	bl m6809Mapper

	add r1,r4,#3
	mov r0,#0x20
	bl m6809Mapper

	ldmfd sp!,{r4,m6809ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
m6809Mapper:		;@ Rom paging..
;@----------------------------------------------------------------------------
	ands r0,r0,#0xFF			;@ Safety
	bxeq lr
	stmfd sp!,{r3-r8,lr}
	ldr r5,=MEMMAPTBL_
	ldr r2,[r5,r1,lsl#2]!
	ldr r3,[r5,#-1024]			;@ RDMEMTBL_
	ldr r4,[r5,#-2048]			;@ WRMEMTBL_

	mov r5,#0
	cmp r1,#0xF9
	movmi r5,#12

	add r6,m6809ptr,#m6809ReadTbl
	add r7,m6809ptr,#m6809WriteTbl
	add r8,m6809ptr,#m6809MemTbl
	b m6809MemAps
m6809MemApl:
	add r6,r6,#4
	add r7,r7,#4
	add r8,r8,#4
m6809MemAp2:
	add r3,r3,r5
	sub r2,r2,#0x2000
m6809MemAps:
	movs r0,r0,lsr#1
	bcc m6809MemApl				;@ C=0
	strcs r3,[r6],#4			;@ readmem_tbl
	strcs r4,[r7],#4			;@ writemem_tb
	strcs r2,[r8],#4			;@ memmap_tbl
	bne m6809MemAp2

;@------------------------------------------
m6809Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
//	reEncodePC

	ldmfd sp!,{r3-r8,lr}
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
WRMEMTBL_:
	.space 256*4
RDMEMTBL_:
	.space 256*4
MEMMAPTBL_:
	.space 256*4
SHARE_RAM:
	.space 0x2000
ROM_Space:
	.space 0x9C200
emptySpace:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
