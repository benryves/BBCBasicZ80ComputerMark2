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
;
	EXTERN	START
	EXTERN	EXPRI
	EXTERN	COMMA
	EXTERN	XEQ
;
	PUBLIC	CLRSCN
	PUBLIC	PUTCSR
	PUBLIC	GETCSR
	PUBLIC	PUTIME
	PUBLIC	GETIME
	PUBLIC	GETKEY
	PUBLIC	BYE
	PUBLIC	CLG
	PUBLIC	COLOUR
	PUBLIC	DRAW
	PUBLIC	GCOL
	PUBLIC	MODE
	PUBLIC	MOVE
	PUBLIC	PLOT
;
	SECTION	PATCH
	ORG		100H
;
;INIT - Perform hardware initialisation.
;
INIT:	CALL	INTIME		;INITIALISE TIMER
	LD	HL,(0001H)
	LD	DE,3*(4-1) ; CONOUT = function 4.
	ADD	HL,DE
	LD	(VDU+1),HL
	JP	START
;
;REBOOT - Stop interrupts and return to CP/M. 
;
BYE:
	; Restore the original ISR.
	DI
	LD	HL,(OLDISR0)
	LD	(39H),HL

	; Disable timer interrupts.
	IN	A,(30H)
	RES	6,A
	OUT	(30H),A
	
	; Acknowledge any outstanding interrupts just in case.
	LD	A,40H
	OUT	(31H),A

	EI
	RST	0
;
VDU: ; Raw output via CONOUT address retrieved from BIOS jump table
	JP 0
;
;INTIME - Initialise CTC to interrupt every 10 ms.
;Also set time to zero.
;
INTIME:	DI

	; Patch the ISR.
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
	LD	C,12
	JP	VDU
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
	LD	C,31
	CALL	VDU
	POP	BC
	CALL	VDU
	POP	BC
	JP	VDU
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
CLG:	; VDU 16
	LD	C,16
	CALL	VDU
	JP	XEQ
;
COLOUR:	; VDU 17,c
	CALL	EXPRI
	EXX
	PUSH HL
	
	LD	C,17
	CALL	VDU
	
	POP	BC
	CALL	VDU
	
	JP	XEQ
;
DRAW:	; VDU 25,5,x;y;
	LD	BC,5
	LD	(PLOTK),BC
	JP	PLOTXY
;
GCOL:	; VDU 18,m,c
	CALL	EXPRI
	EXX
	LD	(GCOLM),HL
	
	CALL	COMMA
	
	CALL	EXPRI
	EXX
	LD	(GCOLC),HL
	
	LD	C,18
	CALL	VDU
	
DEFC	GCOLM	=	$+1
	LD	BC,0
	CALL	VDU

DEFC	GCOLC	=	$+1
	LD	BC,0
	CALL	VDU

	JP	XEQ
;
MODE:	; VDU 22,m
	call	EXPRI
	EXX
	PUSH	HL
	
	LD	C,22
	CALL	VDU
	
	POP	BC
	CALL	VDU
	
	JP	XEQ
;
MOVE:	; VDU 25,4,x;y;
	LD	BC,4
	LD	(PLOTK),BC
	JP	PLOTXY
;
PLOT:	; VDU 25,k,x;y;
	CALL	EXPRI
	EXX
	LD	(PLOTK),HL
	CALL	COMMA
	
PLOTXY:
	CALL	EXPRI
	EXX
	LD	(PLOTX),HL
	CALL	COMMA
	
	CALL	EXPRI
	EXX
	LD	(PLOTY),HL
	
	LD	C,25
	CALL	VDU

DEFC	PLOTK	=	$+1
	LD	BC,0
	CALL	VDU

DEFC	PLOTX	=	$+1
	LD	BC,0
	CALL	VDU
	LD	BC,(PLOTX)
	LD	C,B
	CALL	VDU

DEFC	PLOTY	=	$+1
	LD	BC,0
	CALL	VDU
	LD	BC,(PLOTY)
	LD	C,B
	CALL	VDU
	
	JP	XEQ
;
TIME:	DEFS	4
