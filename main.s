;****************** main.s ***************
; Program written by: Valvano, solution
; Date Created: 2/4/2017
; Last Modified: 1/17/2021
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE2 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE2 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB

       EXPORT  Start
		   
H DCD 267190
L DCD 11

Start
 ; TExaS_Init sets bus clock at 80 MHz
 
     BL  TExaS_Init
	 
; voltmeter, scope on PD3
 ; Initialization goes here
 
 	 LDR R0, =SYSCTL_RCGCGPIO_R ;R0 points to GPIO clock
	 LDR R1, [R0] ;read SYSCTL_RCGCGPIO_R into R1
	 ORR R1, #0x30 ;turn on Port E and Port F clock
	 STR R1, [R0] ;write back to SYSCTL_RCGCGPIO_R
	 
	 NOP ;waiting
	 NOP

	 LDR R1, =GPIO_PORTF_LOCK_R; unlocks the lock register
	 LDR R0, =GPIO_LOCK_KEY
	 STR R0, [R1]

	 LDR R0, =GPIO_PORTF_CR_R ;i dont know if I need to enable commit
	 LDR R1, [R0]
	 ORR R1, #0x10
	 STR R1, [R0]
	 
	 LDR R0, =GPIO_PORTE_AFSEL_R
   	 LDR R1, [R0]
   	 BIC R1, #0x06
   	 STR R1, [R0]

	
	 LDR R0, =GPIO_PORTF_AFSEL_R
   	 LDR R1, [R0]
   	 BIC R1, #0x10
   	 STR R1, [R0]

	 
	 LDR R0, =GPIO_PORTF_PUR_R
   	 LDR R1, [R0]
   	 ORR R1, #0x10
   	 STR R1, [R0]


	 LDR R0, =GPIO_PORTE_DEN_R
	 LDR R1, [R0] 
	 ORR R1, #0x06 ;Enable PE1, PE2
	 STR R1, [R0]
	 
	 LDR R0, =GPIO_PORTF_DEN_R
	 LDR R1, [R0]
	 ORR R1, #0x10 ;Enable PF4
	 STR R1, [R0]
	 
	 LDR R0, =GPIO_PORTF_DIR_R
	 LDR R1, [R0]
	 BIC R1, #0x10 ;PF4 input
	 STR R1, [R0]
	 
	 LDR R0, =GPIO_PORTE_DIR_R
	 LDR R1, [R0]
	 ORR R1, #0x04 ;PE2 output
	 BIC R1, #0x02 ;PE1 input
	 STR R1, [R0] 
	 
	 AND R2, R2, #0
	 AND R5, R5, #0
	 LDR R10, =800000
  
    

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
; R6 WILL BE THE TIME IT IS ON WHILE R3 WILL BE TIME IT IS OFF

	 
	
	 LDR R0, =GPIO_PORTE_DATA_R ;R0 = [Data]
	 LDR R1, [R0] ;R1 = Data
	 ORR R1, #0x04 ;Turns PE2 on
	 STR R1, [R0] ;store PE2 on
	
	 
	 BL DELAY30 ;wait 150ms
	 
	 LDR R1, [R0] ;reload data
	 BIC R1, #0x04 ;Clear PE2 bit
	 STR R1, [R0] ;store data to turn PE2 off
	 
	 BL DELAY70 ;wait 350ms
	 BL CHECKPE1 ;check for PE1 input
	 
	 
     
BAC	 B    loop
	 	 

DELAY30 LDR R6, =2400000 ;x8
LOP  SUBS R6, R6, #1 ;subtract one until R6 == 0
	 CMP R6, #0
	 BNE LOP
	 LDR R6, =2400000
	 BX LR
	 
DELAY70 LDR R3, =5600000
MOP  SUBS R3, R3, #1 ;subtract 1 until R3 == 0
	 CMP R3, #0
	 BNE MOP
	 LDR R3, =5600000
 	 BX LR

		
   
BREATHE		
		BL CHECK_PRESS
		LDR R2, =GPIO_PORTE_DATA_R ;this is where I want to chagne the LED brightness
		LDR R7, [R2]
		ORR R7, #0x04 ;turn on light
		STR R7, [R2]

		LDR R9, H ;time that the LED will stay on during PWM
		LDR R8, L ;time that the LED will stay off during PWM
REPEAT 
		LDR R2, =GPIO_PORTE_DATA_R ;increase frequency until unable
		LDR R7, [R2]
		ORR R7, #4
		STR R7, [R2]

		BL DELAYON ;awit for H time

		BIC R7, #4
		STR R7, [R2]

		BL DELAYOFF ;wait for L time

		BL CHECK_PRESS ;check if PF4 is still pressed
		ADD R8, #1 ;increase L
		SUBS R9, #1 ;decrease H
		CMP R9, #11 ;when it canot be slower then leave
		BNE REPEAT

REPEAT1	LDR R2, =GPIO_PORTE_DATA_R ;decrease frequency until visible by the human eye
		LDR R7, [R2]
		ORR R7, #4
		STR R7, [R2]

		BL DELAYON ;awit for H time

		BIC R7, #4
		STR R7, [R2]

		BL DELAYOFF ;wait for L time

		BL CHECK_PRESS ;check if PF4 is still pressed
		SUBS R8, #1 ;decrease L
		ADD R9, #1 ;increase H
		CMP R8, #11 ;when it canot be slower then leave
		BNE REPEAT1

		B BREATHE

CHECK_PRESS LDR R2, =GPIO_PORTF_DATA_R
		LDR R7, [R2] ;check if PF4 is being pressed
		AND R7, #32 ;isolate PF4
		EOR R7, R7, #0x10 ;using negative logic, so check if bit 5 is 0
		CMP R7, #32
		BNE UU ;go back to main engine if PF4 is not pressed
		LDR R2, =GPIO_PORTE_DATA_R ;reload LED output
		LDR R7, [R2]
		BX LR

DELAYON ADD R11, R7, #0 ;put H in R11
AGAIN 	SUBS R11, #1 ;subtract 1 from H until it is no more
		CMP R11, #0
		BNE AGAIN

		BX LR ;return

DELAYOFF ADD R11, R8, #0 ;put L in R11
AGAIN1 SUBS R11, #1 ;subtract 1 from L until it is no more
		CMP R11, #0
		BNE AGAIN1

		BX LR ;return

SWITCH LDR R2, =GPIO_PORTE_DATA_R ;this is where I want to chagne the LED brightness
			LDR R7, [R2]
			AND R7, #0x4
			BEQ TURN_OFF
			ORR R7, #0x04 ;turn on light
			B LEAVE
TURN_OFF 	BIC R7, #0x04
LEAVE 		STR R7, [R2]


CHANGE LDR R6, =800000
MOPPP  LDR R3, =7200000
	   CMP R6, R3
	   BNE NN
	 

	 
PREESED  ;This will now go do the duty cycle till there is another change
		; BEQ CHANGE
NN		 LDR R0, =GPIO_PORTE_DATA_R
		 LDR R1, [R0]
		 AND R1, R1, #0x02
		 CMP R1, #2
		 BEQ NN
		 LDR R0, =GPIO_PORTE_DATA_R
		 LDR R1, [R0]
		 ORR R1, #0x04
		 STR R1, [R0]
		 ADD R2, R2, R6
		 ADD R5, R5, R3
YEE		 SUBS R2, R2, #1
	     CMP R2, #0
	     BNE YEE
		 LDR R1, [R0]
	     BIC R1, #0x04
	     STR R1, [R0]
NO		 SUBS R5, R5, #1
	     CMP R5, #0
		 BNE NO
		 LDR R0, =GPIO_PORTE_DATA_R ;checking if the button is pressed
		 LDR R1, [R0]
		 AND R1, R1, #0x02
		 CMP R1, #2
		 BNE PREESED
		 BL HERE
		 

CHECKPE1 LDR R0, =GPIO_PORTE_DATA_R ;R0 = [Data]
		 LDR R1, [R0] ;R1 = Data
		 AND R1, R1, #0x02 ;isolate PE1
		 CMP R1, #2 ; check if PE1 is on DO NOT CHANGE R10 R6 R3 R2 R5 PLS for the new one use like registers
		 BNE BAC ;return to main engine if PE1 is off
HERE     LDR R2, =GPIO_PORTF_DATA_R ;R2 = PortF [Data]
		 LDR R7, [R2] ;R7 = PortF Data
		 EOR R7, R7, #0x10
		 CMP R7, #0x10 ;
		 BEQ BREATHE ; if PortF Data is on then breathe THIS IS BASCIALLY CHECKING IF THE LED NEEDS TO DO BREATHING 
UU		 CMP R3, R10 ;compare 
		 BEQ CHANGE
		 LDR R8, =1600000 ;THIS IS CHANGING THE DUTY CYCLE
		 ADD R6, R6, R8
	     LDR R9, =1600000
		 SUB R3, R3, R9
		 BL PREESED	 ;THIS IS THE INFINITE LOOP THAT WE IMPLEMENT UNTIL THERE IS ANOTHER CHANGE
		 
	 
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
