#ifdef __arm__

#include "YM2151/YM2151.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global YM2151_0
	.global YM0_R
	.global YM0_W
	.global setMuteSoundGUI
	.global setMuteSoundGame

	.extern pauseEmulation


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldmfd sp!,{lr}
//	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr ymptr,=YM2151_0
	bl YM2151Reset			;@ Sound
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
setMuteSoundGame:			;@ For System E ?
;@----------------------------------------------------------------------------
	strb r0,muteSoundGame
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer
;@----------------------------------------------------------------------------
;@	mov r11,r11
	stmfd sp!,{r0,r1,lr}

	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	ldr ymptr,=YM2151_0
	bl YM2151Mixer

	ldmfd sp!,{r0,r1}
	mov r12,r0
	ldr r3,pcmPtr0
wavLoop:
	ldrb r2,[r3],#1
	mov r2,r2,lsl#8
	subs r12,r12,#1
	strhpl r2,[r1],#2
	bhi wavLoop

	ldmfd sp!,{lr}
	bx lr

silenceMix:
	ldmfd sp!,{r0,r1}
	mov r12,r0
	mov r2,#0
silenceLoop:
	subs r12,r12,#2
	strpl r2,[r1],#4
	bhi silenceLoop

	ldmfd sp!,{lr}
	bx lr


;@----------------------------------------------------------------------------
YM0_R:
;@----------------------------------------------------------------------------
	bic r1,r12,#0x0001
	cmp r1,#0x2000
	bne empty_IO_R
	tst r12,#1
	ldr ymptr,=YM2151_0
	mov r0,#0
	bne YM2151DataR
	bx lr
;@----------------------------------------------------------------------------
YM0_W:
;@----------------------------------------------------------------------------
	bic r1,r12,#0x0001
	cmp r1,#0x2000
	bne empty_IO_W
	tst r12,#1
	ldr ymptr,=YM2151_0
	bne YM2151DataW
	b YM2151IndexW

;@----------------------------------------------------------------------------
pcmPtr0:	.long WAVBUFFER
pcmPtr1:	.long WAVBUFFER+528

muteSound:
muteSoundGUI:
	.byte 0
muteSoundGame:
	.byte 0
	.space 2

	.section .bss
	.align 2
YM2151_0:
	.space ymSize
WAVBUFFER:
	.space 0x1000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
