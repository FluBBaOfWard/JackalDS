#ifdef __arm__

#include "ARM6809/ARM6809.i"
#include "K005849/K005849.i"

	.global ioReset
	.global IO_R
	.global IO_W
	.global refreshEMUjoypads

	.global joyCfg
	.global EMUinput
	.global g_dipSwitch0
	.global g_dipSwitch1
	.global g_dipSwitch2
	.global g_dipSwitch3
	.global coinCounter0
	.global coinCounter1

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------
		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	mov r3,r4
	and r0,r4,#0xf0
		ldr r2,joyCfg
		andcs r4,r4,r2
		tstcs r4,r4,lsr#10		;@ L?
		andcs r4,r4,r2,lsr#16
	ldr r1,=k005885_0
	ldrb r1,[r1,#irqControl]
	tst r1,#0x08				;@ Screen flip?
	adreq r1,rlud2lrud90
	adrne r1,rlud2lrud270
	ldrb r0,[r1,r0,lsr#4]


	ands r1,r4,#3				;@ A/B buttons to Shot/Grenade
	cmpne r1,#3
	tstne r2,#0x400				;@ Swap A/B?
	eorne r1,r1,#3

	orr r0,r0,r1,lsl#4
	mov r1,#0
//	tst r3,#0x400				;@ X
	tst r3,#0x800				;@ Y
	orrne r1,r1,#0x40

	mov r3,#0
	tst r4,#0x4					;@ Select
	orrne r3,r3,#0x01			;@ Coin
	tst r4,#0x8					;@ Start
	orrne r3,r3,#0x08			;@ Start
	tst r2,#0x20000000			;@ Player2?
	movne r2,r0
	movne r0,r1
	movne r1,r2
	movne r3,r3,lsl#1

	strb r0,joy0State
	strb r1,joy1State
	strb r3,joy2State
	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
playerCount:.long 0			;@ Number of players in multilink.
joySerial:	.byte 0
joy0State:	.byte 0
joy1State:	.byte 0
joy2State:	.byte 0
rlud2lrud:		.byte 0x00,0x02,0x01,0x03, 0x04,0x06,0x05,0x07, 0x08,0x0a,0x09,0x0b, 0x0c,0x0e,0x0d,0x0f
rlud2lrud180:	.byte 0x00,0x01,0x02,0x03, 0x08,0x09,0x0a,0x0b, 0x04,0x05,0x06,0x07, 0x0c,0x0d,0x0e,0x0f
rlud2lrud90:	.byte 0x00,0x08,0x04,0x0c, 0x02,0x0a,0x06,0x0e, 0x01,0x09,0x05,0x0d, 0x03,0x0b,0x07,0x0f
rlud2lrud270:	.byte 0x00,0x04,0x08,0x0c, 0x01,0x05,0x09,0x0d, 0x02,0x06,0x0a,0x0e, 0x03,0x07,0x0b,0x0f
g_dipSwitch0:	.byte 0
g_dipSwitch1:	.byte 0x85		;@ Lives, cabinet & demo sound.
g_dipSwitch2:	.byte 0
g_dipSwitch3:	.byte 0
coinCounter0:	.long 0
coinCounter1:	.long 0

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
Input0_R:		;@ Player 1
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy0State
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input1_R:		;@ Player 2
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy1State
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input2_R:		;@ Coins, Start & Service
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,g_dipSwitch3
	ldrb r1,joy2State
	orr r0,r0,r1
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input3_R:
;@----------------------------------------------------------------------------
	ldrb r0,g_dipSwitch0
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input4_R:
;@----------------------------------------------------------------------------
	ldrb r0,g_dipSwitch1
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input5_R:
;@----------------------------------------------------------------------------
	ldrb r0,g_dipSwitch2
	eor r0,r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
IO_R:						;@ I/O read (0x0010-0x0018)
;@----------------------------------------------------------------------------
	subs r1,addy,#0x0010
	bmi k005885_0R
	cmp r1,#0x0009
	ldrmi pc,[pc,r1,lsl#2]
;@---------------------------
	b k005885_0R
;@io_read_tbl
	.long Input4_R				;@ 0x0010
	.long Input0_R				;@ 0x0011
	.long Input1_R				;@ 0x0012
	.long Input2_R				;@ 0x0013
	.long empty_IO_R			;@ 0x0014
	.long empty_IO_R			;@ 0x0015
	.long empty_IO_R			;@ 0x0016
	.long empty_IO_R			;@ 0x0017
	.long Input5_R				;@ 0x0018

;@----------------------------------------------------------------------------
IO_W:						;@I/O write (0x0019,0x001C)
;@----------------------------------------------------------------------------
	cmp addy,#0x0019
	beq watchDogW
	cmp addy,#0x001C
	beq coinW
	b k005885_0W

;@----------------------------------------------------------------------------
watchDogW:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
coinW:
;@----------------------------------------------------------------------------
setBank:
	ldr r1,=chipBank
	strb r0,[r1]
	stmfd sp!,{r0,lr}
	bl jackalMapper
	ldmfd sp!,{r0,lr}


	tst r0,#0x01
	ldrne r1,coinCounter0
	addne r1,r1,#1
	strne r1,coinCounter0
	tst r0,#0x02
	ldrne r1,coinCounter1
	addne r1,r1,#1
	strne r1,coinCounter1
//	tst r0,#0x04			;@ END?

	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
