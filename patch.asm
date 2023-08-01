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
	EXTERN	BRAKET
	EXTERN	XEQ
	EXTERN	OSWRCH
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
	PUBLIC	POINT
	PUBLIC	OSBYTE
	PUBLIC	OSWORD
	PUBLIC	OSNEWL
	PUBLIC	OSASCI
	PUBLIC	VDU
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
	LD	A,134
	CALL	OSBYTE
	EX	DE,HL
	LD	L,D
	LD	D,0
	LD	H,0
	RET
;
CLG:	; VDU 16
	LD	C,16
	CALL	VDU
	JP	XEQ
;
COLOUR:	; VDU 17,c / VDU 19,l,p,0,0,0 / VDU 19,l,16,r,g,b
	CALL	EXPRI
	EXX
	LD	(COLOUR0),HL
	
	LD	A,(IY)
	CP	','
	JR	NZ,COLOURT
	INC	IY
		
	CALL	EXPRI
	EXX
	LD	(COLOUR1),HL
	
	LD	A,(IY)
	CP	','
	JR	NZ,COLOURP
	INC	IY
	
	CALL	EXPRI
	EXX
	LD	(COLOUR2),HL

	CALL	COMMA
	
	CALL	EXPRI
	EXX
	LD	(COLOUR3),HL

COLOURRGB:	; COLOUR l,r,g,b (set logical to RGB colour)
	LD	C,19
	CALL	VDU

	LD	BC, (COLOUR0)
	CALL	VDU
	
	LD	C,16
	CALL	VDU

	LD	BC,(COLOUR1)
	CALL VDU
DEFC	COLOUR2	=	$+1
	LD	BC,0
	CALL VDU
DEFC	COLOUR3	=	$+1
	LD	BC,0
	CALL VDU
	
	JP	XEQ

COLOURT:	; COLOUR c (text)
	LD	C,17
	CALL	VDU

DEFC	COLOUR0	=	$+1
	LD	BC,0
	CALL	VDU
	
	JP	XEQ

COLOURP:	; COLOUR l,p (set logical to physical colour)
	LD	C,19
	CALL	VDU
	
	LD	BC, (COLOUR0)
	CALL	VDU

DEFC	COLOUR1	=	$+1
	LD	BC,0
	CALL VDU
	
	LD	B,3
COLOUR000:
	PUSH	BC
	LD	C,0
	CALL	VDU
	POP	BC
	DJNZ	COLOUR000
	
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
; POINT: Read the colour of a screen pixel
POINT:
	LD	A,(IY)
	CP	'('
	JR	NZ,POINT0
	INC	IY
POINT0:
	CALL	EXPRI
	EXX
	LD	(POINTARGX),HL
	CALL	COMMA
	CALL	EXPRI
	EXX
	LD	(POINTARGY),HL
	CALL	BRAKET
	; OSWORD 9
	LD	A,9
	LD	HL,POINTARGS
	CALL	OSWORD
	; Convert result
	LD	A,(POINTRES)
	LD	L,A
	ADD	A,A
	SBC A,A
	LD	H,A
	EXX
	SBC	HL,HL
	XOR	A
	LD	C,A
	RET
POINTARGS:
POINTARGX:
	DEFW	0
POINTARGY:
	DEFW	0
POINTRES:
	DEFB	0
;
; OSASCI: Write character but turn CR into CRLF
OSASCI:
	CP	13
	JP	NZ,OSWRCH
;
; OSNEWL: Write CRLF
OSNEWL:
	LD	A,13
	CALL	OSWRCH
	LD	A,10
	JP	OSWRCH
;
; OSBYTE:
OSBYTE:
	LD	C,A
	IN	A,(1)	; Dummy read to clear write queue
	LD	A,C
	OUT	(1),A	; Command
	LD	A,L
	OUT	(1),A	; X
	LD	A,H
	OUT	(1),A	; Y
	IN	A,(1)	; Response
	LD	C,A
	IN	A,(1)	; X
	LD	L,A
	IN	A,(1)	; Y
	LD	H,A
	LD	C,A
	RET
;
; OSWORD:
OSWORD:
	LD	C,A
	IN	A,(2)	; Dummy read to clear write queue
	LD	A,C
	OUT	(2),A	; Command
	LD	A,L
	OUT	(2),A	; X (LSB)
	LD	A,H
	OUT	(2),A	; Y (MSB)
	IN	A,(2)	; Response
	LD	C,A
	IN	A,(2)	; X
	LD	L,A
	IN	A,(2)	; Y
	LD	H,A
	LD	C,A
	RET
;
TIME:	DEFS	4
