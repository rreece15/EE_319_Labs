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

	 
	
	 LDR R0, =GPIO_PORTE_DATA_R
	 LDR R1, [R0]
	 ORR R1, #0x04
	 STR R1, [R0]
	
	 
	 BL DELAY30
	 
	 LDR R1, [R0]
	 BIC R1, #0x04
	 STR R1, [R0]
	 
	 BL DELAY70
	 BL CHECKPE1
	 
	 
     
BAC	 B    loop
	 	 

DELAY30 LDR R6, =2400000 ;x8
LOP  SUBS R6, R6, #1
	 CMP R6, #0
	 BNE LOP
	 LDR R6, =2400000
	 BX LR
	 
DELAY70 LDR R3, =5600000
MOP  SUBS R3, R3, #1
	 CMP R3, #0
	 BNE MOP
	 LDR R3, =5600000
 	 BX LR

		
   
HAA		
		LDR R2, =GPIO_PORTF_DATA_R ;this is where I want to chagne the LED brightness
		LDR R7, [R2]
		CMP R7, #32
		BNE UU


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
		 

CHECKPE1 LDR R0, =GPIO_PORTE_DATA_R
		 LDR R1, [R0]
		 AND R1, R1, #0x02
		 CMP R1, #2 ; DO NOT CHANGE R10 R6 R3 R2 R5 PLS for the new one use like registers 
		 BNE BAC
HERE     LDR R2, =GPIO_PORTF_DATA_R
		 LDR R7, [R2]
		 CMP R7, #32
		 BEQ HAA		; THIS IS BASCIALLY CHECKING IF THE LED NEEDS TO DO BREATHING 
UU		 CMP R3, R10
		 BEQ CHANGE
		 LDR R8, =1600000 ;THIS ISCHANGING THE DUTY CYCLE
		 ADD R6, R6, R8
	     LDR R9, =1600000
		 SUB R3, R3, R9
		 BL PREESED	 ;THIS IS THE INFINITE LOOP THAT WE IMPLEMETN UNTIL THERE IS ANOTHER CHANGE
		 
	 





      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
