;	TITLE	BBC BASIC (C) R.T.RUSSELL 1984
;
;BBC BASIC (Z80) - CP/M VERSION.
;(C) COPYRIGHT R.T.RUSSELL, 1984.
;ALL RIGHTS RESERVED.
;
;THIS PROGRAM ALLOWS THE USER TO ADAPT BBC BASIC TO THE
;PARTICULAR CHARACTERISTICS OF HIS SYSTEM HARDWARE ETC.
;
;THE PROGRAM RESIDES AT 100H FOR EASE OF LOADING.
;*** IT MUST NOT EXCEED 256 BYTES IN TOTAL LENGTH ***
;
;PLEASE NOTE THAT A Z80 PROCESSOR AND CP/M VERSION 2.2
;OR LATER ARE REQUIRED.
;
;R.T.RUSSELL, 04-02-1984
;
BDOS	EQU	5
C_WRITE	EQU	2
COLD	EQU	200H
;
	PUBLIC	CLRSCN
	PUBLIC	PUTCSR
	PUBLIC	GETCSR
	PUBLIC	PUTIME
	PUBLIC	GETIME
	PUBLIC	GETKEY
	PUBLIC	BYE
;
	SECTION	PATCH
	ORG		100H
;
;INIT - Perform hardware initialisation.
;
INIT:	CALL	INTIME		;INITIALISE TIMER
	JP	COLD
;
;REBOOT - Stop interrupts and return to CP/M. 
;
BYE:
	; Restore the original ISR.
	DI
	LD	HL,(OLDISR0)
	LD	(39H),HL
	EI
	RST	0
;
;INTIME - Initialise CTC to interrupt every 10 ms.
;Also set time to zero.
;
INTIME:	DI

	; Patch the ISR.
	DI
	LD	HL,(39H)
	LD	(OLDISR0),hl
	LD	(OLDISR1),hl
	LD	HL,ISR
	LD	(39H),hl
	
	; Enable timer interrupts.
	IN	A,(30H)
	SET	6,A
	OUT	(30H),A

	; Reset timer.
	LD	HL,0
	LD	(TIME),HL
	LD	(TIME+2),HL
	EI
	RET
;
;TIMER - Interrupt service routine.
;Increments elapsed-time clock 100 times per second.
;
ISR:	PUSH	AF

	; Is it a timer interrupt?
	IN	A,(31H)
	BIT	6,A
	JR	Z,TIMER
	POP	AF
DEFC	OLDISR0	=	$+1
	JP	0

TIMER:
	; Acknowledge timer interrupt.
	LD	A,40H
	OUT	(31H),A
	
	PUSH	BC
	PUSH	HL
	LD	HL,TIME
	LD	B,4
UPT1:	INC	(HL)
	JR	NZ,EXIT
	INC	HL
	DJNZ	UPT1
EXIT:	POP	HL
	POP	BC
	POP	AF
DEFC	OLDISR1	=	$+1
	JP	0
;
;GTIME - Read elapsed-time clock.
;  Outputs: DEHL = elapsed time (centiseconds)
; Destroys: A,D,E,H,L,F
;
GETIME:	DI
	LD	HL,(TIME)
	LD	DE,(TIME+2)
	EI
	RET
;
;PUTIME - Load elapsed-time clock.
;   Inputs: DEHL = time to load (centiseconds)
; Destroys: A,D,E,H,L,F
;
PUTIME:	DI
	LD	(TIME),HL
	LD	(TIME+2),DE
	EI
	RET
;
;CLRSCN - Clear screen.
; Destroys: A,D,E,H,L,F
;
CLRSCN:	; VDU 12
	LD	E,12
	LD	C,C_WRITE
	CALL	BDOS
	RET
;
;GETKEY - Sample keyboard with specified wait.
;   Inputs: HL = Time to wait (centiseconds)
;  Outputs: Carry reset indicates time-out.
;           If carry set, A = character typed.
; Destroys: A,D,E,H,L,F
;
GETKEY:	PUSH	BC
	PUSH	HL
	LD	C,6
	LD	E,0FFH
	CALL	BDOS		;CONSOLE INPUT
	POP	HL
	POP	BC
	OR	A
	SCF
	RET	NZ		;KEY PRESSED
	OR	H
	OR	L
	RET	Z		;TIME-OUT
	PUSH	HL
	LD	HL,TIME
	LD	A,(HL)
WAIT1:	CP	(HL)
	JR	Z,WAIT1		;WAIT FOR 10 ms.
	POP	HL
	DEC	HL
	JR	GETKEY
;
;PUTCSR - Move cursor to specified position.
;   Inputs: DE = horizontal position (LHS=0)
;           HL = vertical position (TOP=0)
; Destroys: A,D,E,H,L,F
;
;
PUTCSR:	; VDU 31,x,y
	PUSH	HL
	PUSH	DE
	LD	E,31
	LD	C,C_WRITE
	CALL	BDOS
	POP	DE
	LD	C,C_WRITE
	CALL	BDOS
	POP	DE
	LD	C,C_WRITE
	CALL	BDOS
	RET
;
;GETCSR - Return cursor coordinates.
;   Outputs:  DE = X coordinate (POS)
;             HL = Y coordinate (VPOS)
;  Destroys: A,D,E,H,L,F
;
GETCSR:
	; TODO
	LD	HL,0
	LD	DE,0
	RET
;
TIME:	DEFS	4
;
	IF	$ > 1F4H
	ERROR	"INSUFFICIENT SPACE"
	ENDIF
;
	SECTION	KEYB
	ORG		1F4H
;
	DEFB	80		;WIDTH
	DEFB	'K' & 1FH	;CURSOR UP
	DEFB	'J' & 1FH	;CURSOR DOWN
	DEFB	'L' & 1FH	;START OF LINE
	DEFB	'B' & 1FH	;END OF LINE
	DEFB	'C' & 1FH	;DELETE TO END OF LINE
	DEFB	08H		;BACKSPACE
	DEFB	'X' & 1FH	;CANCEL LINE
	DEFB	'H' & 1FH	;CURSOR LEFT
	DEFB	'I' & 1FH	;CURSOR RIGHT
	DEFB	'E' & 1FH	;DELETE CHARACTER
	DEFB	'A' & 1FH	;INSERT CHARACTER
