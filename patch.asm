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
S_SYSVAR	EQU	49
CONW	EQU	1Ah
CONH	EQU	1Ch
;
	EXTERN	START
	EXTERN	EXPRI
	EXTERN	COMMA
	EXTERN	BRAKET
	EXTERN	XEQ
	EXTERN	OSWRCH
	EXTERN	TRAP
	EXTERN	OSKEY
	EXTERN	KEYB
	EXTERN	COUNT
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
	PUBLIC	ENVEL
	PUBLIC	SOUND
	PUBLIC	ADVAL
	PUBLIC	OSBYTE
	PUBLIC	OSWORD
	PUBLIC	OSNEWL
	PUBLIC	OSASCI
	PUBLIC	OSCMD
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
	
	LD DE,3*(30-4) ; USERF = function 30.
	ADD	HL,DE
	LD	(USERF+1),HL
	
	CALL	MODECHG
	JP	START
;
;REBOOT - Stop interrupts and return to CP/M. 
;
BYE:
	RST	0
;
VDU: ; Raw output via CONOUT address retrieved from BIOS jump table
	JP 0
;
USERF: ; USERF BIOS routine
	JP 0
;
;INTIME - Initialise CTC to interrupt every 10 ms.
;Also set time to zero.
;
INTIME:
	RET
;
;GTIME - Read elapsed-time clock.
;  Outputs: DEHL = elapsed time (centiseconds)
; Destroys: A,D,E,H,L,F
;
GETIME:
	CALL	READTIME
	LD	HL,(TIME)
	LD	DE,(TIME+2)
	RET
;
;READTIME - Read elapsed-time clock from hardware into local TIME variable.
;  Outputs: TIME = elapsed time (centiseconds)
; Destroys: A,H,L,F
;
READTIME:
	LD	HL,TIME
	LD	A,1
	JP	OSWORD
;
;PUTIME - Load elapsed-time clock.
;   Inputs: DEHL = time to load (centiseconds)
; Destroys: A,D,E,H,L,F
;
PUTIME:
	LD	(TIME),HL
	LD	(TIME+2),DE
	CALL	WRITETIME
	RET
;
;WRITETIME - Writes elapsed-time clock from local TIME variable to hardware.
;   Inputs: TIME = elapsed time (centiseconds)
; Destroys: A,H,L,F
;
WRITETIME:
	LD	HL,TIME
	LD	A,2
	JP	OSWORD
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
GETKEY:
	BIT	7,H
	JR	NZ,GETKEYN
	PUSH	BC
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
	CALL	READTIME
	LD	HL,TIME
	LD	A,(HL)
WAIT1:
	PUSH	AF
	PUSH	HL
	CALL	READTIME
	POP	HL
	POP	AF
	CP	(HL)
	JR	Z,WAIT1		;WAIT FOR 10 ms.
	POP	HL
	DEC	HL
	JR	GETKEY
GETKEYN:
	; Negative GETKEY, use OSBYTE
	LD	A,129
	CALL	OSBYTE
	LD	A,L
	OR	A
	RET	NZ
	CCF
	RET
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
	
	CALL	MODECHG
	
	XOR	A
	LD	(COUNT),A
	
	JP	XEQ
;
MODECHG:
	; Fetch the current mode.
	LD	A,135
	CALL	OSBYTE
	LD	A,H
	AND	7
	ADD	A,A
	LD	L,A
	LD	H,0
	LD	DE,MODESIZES
	ADD	HL,DE
	
	; Set screen width in KEYB settings.
	LD	A,(HL)
	LD	(KEYB-12),A
	
	; Write console width -1 to SCB.
	PUSH	HL
	DEC	A
	LD	B,CONW
	CALL	WRITESCB
	
	; Write console height -1 to SCB.
	POP	HL
	INC	HL
	LD	A,(HL)
	DEC	A
	LD	B,CONH
	CALL	WRITESCB
	
	RET
MODESIZES:
	DEFB	80, 32 ; 0
	DEFB	40, 32 ; 1
	DEFB	20, 32 ; 2
	DEFB	80, 25 ; 3
	DEFB	40, 32 ; 4
	DEFB	20, 32 ; 5
	DEFB	40, 25 ; 6
	DEFB	40, 25 ; 7
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
; ENVEL:  Define a pitch and amplitude envelope
ENVEL:
	LD	IX,ENVELARGS
	PUSH	IX
	CALL	EXPRI
	EXX
	POP	IX
	LD	(IX),L
	INC	IX
	LD	B,13
ENVEL0:
	PUSH	BC
	PUSH	IX
	CALL	COMMA
	CALL	EXPRI
	EXX
	POP	IX
	POP	BC
	LD	(IX),L
	INC	IX
	DJNZ	ENVEL0
	LD	A,8
	LD	HL,ENVELARGS
	CALL	OSWORD
	JP	XEQ
ENVELARGS:
	DS	14
;
; SOUND: Make a sound
SOUND:
	; Collect the four SOUND arguments
	LD	IX,SOUNDARGS
	PUSH	IX
	CALL	EXPRI
	EXX
	POP	IX
	LD	(IX),L
	INC	IX
	LD	(IX),H
	INC	IX
	LD	B,3
SOUND0:
	PUSH	BC
	PUSH	IX
	CALL	COMMA
	CALL	EXPRI
	EXX
	POP	IX
	POP	BC
	LD	(IX),L
	INC	IX
	LD	(IX),H
	INC	IX
	DJNZ	SOUND0
SOUND1:
	; Check whether the sound buffer has some space in it.
	LD	A,(SOUNDARGS)
	AND	3
	NEG
	SUB	5
	LD	L,A
	LD	H,-1
	LD	A,128
	CALL	OSBYTE
	; Are there 0 bytes free in the sound buffer?
	LD	A,L
	OR	H
	JR	NZ,SOUND2
	; Zero bytes free, so check for Esc then loop.
	CALL	TRAP
	JR	SOUND1
SOUND2:
	; Send the SOUND command via OSWORD
	LD	A,7
	LD	HL,SOUNDARGS
	CALL	OSWORD
	JP	XEQ
SOUNDARGS:
	DS	8
;
; ADVAL - Read analogue-digital convertor etc:
ADVAL:
	CALL	EXPRI
	EXX

	LD	A,128
	CALL	OSBYTE
	
	; Convert HL (result) to HLH'L'
	LD	A,H
	EXX
	ADD	A,A
	SBC	A,A
	LD	H,A
	LD	L,A
	
	; C = 0 for integer
	XOR	A
	LD	C,A
	RET
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
	PUSH	AF
	CP	15
	JR	NZ,OSBYTENOFLUSH
	PUSH	HL
OSBYTEFLUSH:
	LD	HL,0
	CALL	OSKEY
	JR	C,OSBYTEFLUSH
	POP	HL
OSBYTENOFLUSH:
	POP	AF
	PUSH	BC
	LD	BC,0FFF4H
	CALL	USERF
	POP	BC
	RET
;
; OSWORD:
OSWORD:
	PUSH	BC
	LD	BC,0FFF1H
	CALL	USERF
	POP	BC
	RET
;
; OSCMD:
OSCMD:
	PUSH	BC
	LD	BC,0FFF7H
	CALL	USERF
	POP	BC
	RET
;
TIME:	DEFS	5
;
; WRITESCB: Write CP/M system control block.
WRITESCB:
	LD	(SCBCONDATA),A
	LD	A,B
	LD	(SCBCONOFF),A
	LD	C,S_SYSVAR
	LD	DE,SCBCON
	JP	BDOS
;
SCBCON:
SCBCONOFF:
	DEFB	0
SCBCONCMD:
	DEFB	$FF
SCBCONDATA:
	DEFW	0