#include "ti83plus.inc"
#define  progStart   $9D95
.org     progStart-2
.db      $BB,$6D

; Put number of bytes to read in Ans, maximum are 255
; Call Asm(prgmRECEIVE)
; Get the received bytes as a list in Ans

; #define RECEIVESTUB

; Main entry point.
main:
	; Load the Ans name and find the variable
	bcall(_AnsName)
	bcall(_FindSym)
	jr NC, _found
	
	bcall(_ErrUndefined)
	
_found:
	; Filter out garbage of the file type,
	and a,$1F
	
	; cast RealObj
	cp RealObj
	jp Z,_isReal
	
	bcall(_ErrDataType)

_isReal:
	
	ld h,d
	ld l,e
	bcall(_Mov9ToOP1)
	bcall(_ConvOP1)
	; a now contains our count value
	
	cp 0
	jr Z,_done
	
	ld b, a
	ld hl,buffer
_loop:
	
	push hl
	push bc
	
	call recByte
	
	pop bc
	pop hl
	
	ld a,(receiveStatus)
	cp 0
	jr Z,_done ; when failed, quit
	
	ld a, (inbyte)
	ld (hl), a
	
	inc hl
	
	; counter++
	ld a,(counter)
	inc a
	ld (counter),a
	
	djnz _loop
	
_done:

	
	bcall(_AnsName)
	bcall(_FindSym)
	bcall(_DelVar)
	
	bcall(_AnsName)
	ld a, (counter)
	ld h,0
	ld l,a
	
	; HL = pointer to variable’s symbol table entry
	; DE = pointer to variable’s data storage, size bytes
	bcall(_CreateRList)
	
	ld a,(counter)
	cp 0
	jr Z, _donelist
	ld b,a
	
	; Add 2 to DE
	inc de
	inc de
	
	ld hl,buffer
_initlist:
	
	push bc
	push hl
	
	ld a,(hl)
	
	push de
	ld l,a
	ld h,0
	bcall(_SetXXXXOP2)
	bcall(_OP1ExOP2)
	pop de
	
	; OP1 → *(DE)
	; DE += 9
	bcall(_MovFrOP1)
	
	pop hl
	pop bc
	
	inc hl
	
	djnz _initlist

_donelist:
	
	ret

; Receives a byte
; destroys: all
; affects: receiveStatus, inbyte
recByte:
#ifndef RECEIVESTUB
	AppOnErr(failByte)
	bcall(_RecAByteIO)
	ld (inbyte), a
	AppOffErr
#else
	AppOnErr(failByte)
	ld hl, msgRead
	bcall(_PutS)
	AppOffErr
	ld a,$FF
	ld (inbyte), a
#endif
	ret

; void failByte() { receiveStatus = 0; }
; affects:  receiveStatus
; destroys: a
failByte:
	ld a, 0
	ld (receiveStatus), a
	ret

inbyte:        ; The last byte that was received
	.db $FF
receiveStatus: ; If zero, reception has failed
	.db 1 
counter:       ; A counter that will contain the number of bytes in buffer
	.db 0
buffer:        ; Reception buffer that will be filled with bytes
	.block 256
msgRead:
	.db "R",0


