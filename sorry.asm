;
	PUBLIC	ADVAL
	PUBLIC	PUTIMS
;
	EXTERN	EXTERR
;
	SECTION	CODE
;
ADVAL:
PUTIMS:
	XOR	A
	CALL	EXTERR
	DEFM	"Sorry"
	DEFB	0