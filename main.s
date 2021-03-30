; LCD.s
; Student names: Ayush Bhattacharya and Reece Riherd
; Last modification date: 3/29/2021

; Runs on TM4C123
; Use I2C3 to send data to SSD1306 128 by 64 pixel oLED

; As part of Lab 7, students need to implement I2C_Send2

      EXPORT   I2C_Send2
      PRESERVE8
      AREA    |.text|, CODE, READONLY, ALIGN=2
      THUMB
      ALIGN
I2C3_MSA_R  EQU 0x40023000
I2C3_MCS_R  EQU 0x40023004
I2C3_MDR_R  EQU 0x40023008
; sends two bytes to specified slave
; Input: R0  7-bit slave address
;        R1  first 8-bit data to be written.
;        R2  second 8-bit data to be written.
; Output: 0 if successful, nonzero (error code) if error
; Assumes: I2C3 and port D have already been initialized and enabled
I2C_Send2
;; --UUU-- 
; 1) wait while I2C is busy, wait for I2C3_MCS_R bit 0 to be 0
; 2) write slave address to I2C3_MSA_R, 
;     MSA bits7-1 is slave address
;     MSA bit 0 is 0 for send data
; 3) write first data to I2C3_MDR_R
; 4) write 0x03 to I2C3_MCS_R,  send no stop, generate start, enable
; add 4 NOPs to wait for I2C to start transmitting
; 5) wait while I2C is busy, wait for I2C3_MCS_R bit 0 to be 0
; 6) check for errors, if any bits 3,2,1 I2C3_MCS_R is high 
;    a) if error set I2C3_MCS_R to 0x04 to send stop 
;    b) if error return R0 equal to bits 3,2,1 of I2C3_MCS_R, error bits
; 7) write second data to I2C3_MDR_R
; 8) write 0x05 to I2C3_MCS_R, send stop, no start, enable
; add 4 NOPs to wait for I2C to start transmitting
; 9) wait while I2C is busy, wait for I2C3_MCS_R bit 0 to be 0
; 10) return R0 equal to bits 3,2,1 of I2C3_MCS_R, error bits
;     will be 0 is no error
	PUSH {R4, LR}
L   LDR R3, =I2C3_MCS_R ;step 1-wait for bit 0 to be 0
	LDR R4, [R3]
	AND R4, R4, #0x01
	CMP R4, #0
	BNE L ;loop for 0
	LDR R3, =I2C3_MSA_R ;step 2-write slave addres
	LDR R4, [R3]
	LSL R0, #1
	AND R0, R0, #0x00FE;clear bit 0, 15-8 of slave address
	ADD R4, R4, R0
	STR R4, [R3] ;store slave address
	LDR R3, =I2C3_MDR_R ;step3
	LDR R4, [R3]
	AND R4, R4, #0xFF00 ;clear first 8 bits of data reg
	ADD R4, R4, R1 ;put data into R4
	STR R4, [R3] ;store
	LDR R3, =I2C3_MCS_R ;step 4
	MOV R4, #0x03
	STR R4, [R3]
	NOP
	NOP
	NOP
	NOP
LL  LDR R3, =I2C3_MCS_R ;step 5
	LDR R4, [R3]
	AND R4, R4, #0x01
	CMP R4, #0 ;wait for bit 0 to be 0
	BNE LL
	LDR R3, =I2C3_MCS_R ;step6
	LDR R4, [R3]
	AND R4, R4, #0x0E
	CMP R4, #0 ;if there is no error then continue
	BEQ con
	MOV R0, R4 ;R0 = error bits
	MOV R4, #0x04 ;send stop
	STR R4, [R3]
	B dn ;end
	
con	LDR R3, =I2C3_MDR_R ;step 7
	LDR R4, [R3]
	AND R4, #0xFF00
	ADD R4, R4, R2
	STR R4, [R3]
	
	LDR R3, =I2C3_MCS_R ;step 8
	LDR R4, [R3]
	MOV R4, #0x05
	STR R4, [R3]
	NOP
	NOP
	NOP
	NOP
	
ll	LDR R3, =I2C3_MCS_R ;step 9
	LDR R4, [R3]
	AND R4, R4, #0x01
	CMP R4, #0 ;wait for bit 0 to be 0
	BNE ll
	
	LDR R3, =I2C3_MCS_R ;step 10
	LDR R4, [R3]
	AND R4, #0x0E
	CMP R4, #0
	BEQ Con
	B dn
	
Con	MOV R0, #0
	POP {R4, LR}
dn	BX  LR                          ;   return


    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file