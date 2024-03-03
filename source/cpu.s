#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARM6809/ARM6809.i"
#include "K005849/K005849.i"

#define CYCLE_PSL (H_PIXEL_COUNT/4)

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global cpusSetIRQ

	.global m6809CPU0
	.global m6809CPU1


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]

	ldr r2,=yStart
	ldrb r1,[r2]
	tst r0,#0x200				;@ L?
	subsne r1,#1
	movmi r1,#0
	tst r0,#0x100				;@ R?
	addne r1,#1
	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
	strb r1,[r2]

	bl refreshEMUjoypads		;@ Z=1 if communication ok

;@--------------------------------------
konamiFrameLoop:
;@--------------------------------------
	ldr m6809ptr,=m6809CPU1
	mov r0,#CYCLE_PSL
	bl m6809RestoreAndRunXCycles
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state
;@--------------------------------------
	ldr m6809ptr,=m6809CPU0
	mov r0,#CYCLE_PSL
	bl m6809RestoreAndRunXCycles
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state
;@--------------------------------------
	ldr koptr,=k005885_1
	bl doScanline
	ldr koptr,=k005885_0
	bl doScanline
	cmp r0,#0
	bne konamiFrameLoop

;@--------------------------------------
	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit
	bl paletteTxAll

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
cpusSetIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,m6809ptr,lr}
	ldr m6809ptr,=m6809CPU0
	bl m6809SetIRQPin
	ldmfd sp!,{r0}
	ldr m6809ptr,=m6809CPU1
	bl m6809SetNMIPin
	ldmfd sp!,{m6809ptr,pc}
/*
;@----------------------------------------------------------------------------
cpu0SetIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{m6809ptr,lr}
	ldr m6809ptr,=m6809CPU0
	bl m6809SetIRQPin
	ldmfd sp!,{m6809ptr,pc}
;@----------------------------------------------------------------------------
cpu0SetFIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{m6809ptr,lr}
	ldr m6809ptr,=m6809CPU0
	bl m6809SetFIRQPin
	ldmfd sp!,{m6809ptr,pc}
;@----------------------------------------------------------------------------
cpu1SetFIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{m6809ptr,lr}
	ldr m6809ptr,=m6809CPU1
	bl m6809SetFIRQPin
	ldmfd sp!,{m6809ptr,pc}
;@----------------------------------------------------------------------------
cpu1SetNMI:
;@----------------------------------------------------------------------------
	stmfd sp!,{m6809ptr,lr}
	ldr m6809ptr,=m6809CPU1
	bl m6809SetNMIPin
	ldmfd sp!,{m6809ptr,pc}
*/
;@----------------------------------------------------------------------------
cyclesPerScanline:	.long 0
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:						;@ Return after 1 frame
	.type   stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

;@--------------------------------------
konamiStepLoop:
;@--------------------------------------
	ldr m6809ptr,=m6809CPU1
	mov r0,#CYCLE_PSL
	bl m6809RestoreAndRunXCycles
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state
;@--------------------------------------
	ldr m6809ptr,=m6809CPU0
	mov r0,#CYCLE_PSL
	bl m6809RestoreAndRunXCycles
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state
;@--------------------------------------
	ldr koptr,=k005885_1
	bl doScanline
	ldr koptr,=k005885_0
	bl doScanline
	cmp r0,#0
	bne konamiStepLoop

;@--------------------------------------
	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit
	bl paletteTxAll

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuInit:			;@ Called by machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=m6809CPU0
	bl m6809Init
	ldr r0,=m6809CPU1
	bl m6809Init
	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadcart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 1.5MHz / 60Hz		;Jackal.
	ldr r0,=CYCLE_PSL
	str r0,cyclesPerScanline

;@--------------------------------------
	ldr r0,=m6809CPU0
	bl m6809Reset

;@--------------------------------------
	ldr r0,=m6809CPU1
	bl m6809Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits		;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2
;@----------------------------------------------------------------------------
m6809CPU0:
	.space m6809Size
m6809CPU1:
	.space m6809Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
