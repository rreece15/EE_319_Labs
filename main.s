// TableTrafficLight.c solution to EE319K Lab 5, spring 2021
// Runs on TM4C123
// Moore finite state machine to operate a traffic light.  
// Daniel Valvano, Jonathan Valvano
// January 17, 2021

/* 

 Copyright 2021 by Jonathan W. Valvano, valvano@mail.utexas.edu
    You may use, edit, run or distribute this file
    as long as the above copyright notice remains
 THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
 OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
 VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
 OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 For more information about my classes, my research, and my books, see
 http://users.ece.utexas.edu/~valvano/
 */

// east/west red light connected to PB5
// east/west yellow light connected to PB4
// east/west green light connected to PB3
// north/south facing red light connected to PB2
// north/south facing yellow light connected to PB1
// north/south facing green light connected to PB0
// pedestrian detector connected to PE2 (1=pedestrian present)
// north/south car detector connected to PE1 (1=car present)
// east/west car detector connected to PE0 (1=car present)
// "walk" light connected to PF3-1 (built-in white LED)
// "don't walk" light connected to PF1 (built-in red LED)
#include <stdint.h>
#include "SysTick.h"
#include "TExaS.h"
#include "../inc/tm4c123gh6pm.h"



void DisableInterrupts(void);
void EnableInterrupts(void);

#define SYSCTL_PRGPIO_R         (*((volatile uint32_t *)0x400FEA08))
#define SYSCTL_RCGCGPIO_R       (*((volatile uint32_t *)0x400FE608))

#define GPIO_PORTE_DEN_R        (*((volatile uint32_t *)0x4002451C))
#define GPIO_PORTE_AMSEL_R      (*((volatile uint32_t *)0x40024528))
#define GPIO_PORTE_PCTL_R       (*((volatile uint32_t *)0x4002452C))
#define GPIO_PORTE_DATA_R       (*((volatile uint32_t *)0x400243FC))
#define GPIO_PORTE_DIR_R        (*((volatile uint32_t *)0x40024400))
#define GPIO_PORTE_AFSEL_R      (*((volatile uint32_t *)0x40024420))

	
#define GPIO_PORTB_DEN_R        (*((volatile uint32_t *)0x4000551C))
#define GPIO_PORTB_AMSEL_R      (*((volatile uint32_t *)0x40005528))
#define GPIO_PORTB_PCTL_R       (*((volatile uint32_t *)0x4000552C))
#define GPIO_PORTB_DATA_R       (*((volatile uint32_t *)0x400053FC))
#define GPIO_PORTB_DIR_R        (*((volatile uint32_t *)0x40005400))
#define GPIO_PORTB_AFSEL_R      (*((volatile uint32_t *)0x40005420))

	
#define GPIO_PORTF_DEN_R        (*((volatile uint32_t *)0x4002551C))
#define GPIO_PORTF_AMSEL_R      (*((volatile uint32_t *)0x40025528))
#define GPIO_PORTF_PCTL_R       (*((volatile uint32_t *)0x4002552C))
#define GPIO_PORTF_DATA_R       (*((volatile uint32_t *)0x400253FC))
#define GPIO_PORTF_DIR_R        (*((volatile uint32_t *)0x40025400))
#define GPIO_PORTF_AFSEL_R      (*((volatile uint32_t *)0x40025420))

#define PB543210                (*((volatile uint32_t *)0x400050FC)) // bits 5-0
#define PE210                   (*((volatile uint32_t *)0x4002401C)) // bits 2-0
#define PF321                   (*((volatile uint32_t *)0x40025038)) // bits 3-1

#define GoS 0
#define WaitS 1
#define Stop 2
#define GoW 3
#define WaitW 4
#define Walk 5
#define FlashOn1 6
#define FlashOff1 7
#define FlashOn2 8
#define FlashOff2 9
#define FlashOn3 10
#define FlashOff3 11
#define GoSTemp 12
#define WaitSTemp 13
#define StopTemp 14
#define GoWTemp 15
#define WaitWTemp 16


typedef struct State{
	uint32_t outputB;
	uint32_t outputF;
	uint32_t delay;
	uint32_t next[8];
	
}state;
//If there are multiple buttons pressed, do one request, then the other one
	state FSM[17] = {

	{0x21, 0x02, 100, {WaitS, WaitS, GoS, WaitS, WaitS, WaitS, WaitS, WaitS }}, //GoS
	{0x22, 0x02, 50, {Stop, Stop, Stop, Stop, Stop, Stop, Stop, Stop }}, //WaitS
	{0x24, 0x02, 25, {Stop, GoW, GoS, GoSTemp, Walk, Walk, Walk, Walk}}, //Stop
	{0x0C, 0x02, 100, {WaitW, GoW, WaitW, WaitW, WaitW, WaitW, WaitW, WaitW }}, //GoW
	{0x14, 0x02, 50, {Stop, Stop, Stop, Stop, Stop, Stop, Stop, Stop }}, //WaitW
	{0x24, 0x04, 100, {FlashOn1, FlashOn1, FlashOn1, FlashOn1, FlashOn1, FlashOn1, FlashOn1, FlashOn1 }}, //Walk
	{0x24, 0x02, 50, {FlashOff1, FlashOff1, FlashOff1, FlashOff1, FlashOff1, FlashOff1, FlashOff1, FlashOff1 }}, //Flashon1
	{0x24, 0x00, 50, {FlashOn2, FlashOn2, FlashOn2, FlashOn2, FlashOn2, FlashOn2, FlashOn2, FlashOn2 }}, //Flashoff1
	{0x24, 0x02, 50, {FlashOff2, FlashOff2, FlashOff2, FlashOff2, FlashOff2, FlashOff2, FlashOff2, FlashOff2 }}, //Flashon2
	{0x24, 0x00, 50, {FlashOn3, FlashOn3, FlashOn3, FlashOn3, FlashOn3, FlashOn3, FlashOn3, FlashOn3 }}, //Flashoff2
	{0x24, 0x02, 50, {FlashOff3, FlashOff3, FlashOff3, FlashOff3, FlashOff3, FlashOff3, FlashOff3, FlashOff3 }}, //Flashon3
	{0x24, 0x00, 50, {Stop, GoW, GoS, GoSTemp, Walk, GoW, GoS, GoSTemp }}, //Flashoff3
  {0x21, 0x02, 100, {WaitSTemp, WaitSTemp, WaitSTemp, WaitSTemp, WaitSTemp, WaitSTemp, WaitSTemp, WaitSTemp}}, //GoSTemp
	{0x22, 0x02, 50, {StopTemp, StopTemp, StopTemp, StopTemp, StopTemp, StopTemp, StopTemp, StopTemp}}, //WaitSTemp
	{0x24, 0x02, 25, {GoWTemp, GoWTemp, GoWTemp, GoWTemp, GoWTemp, GoWTemp, GoWTemp, GoWTemp}}, //StopTemp
	{0x0C, 0x02, 100, {WaitWTemp, WaitWTemp, WaitWTemp, WaitWTemp, WaitWTemp, WaitWTemp, WaitWTemp, WaitWTemp}}, //GoWTemp
	{0x14, 0x02, 50, {Stop, Stop, Stop, Stop, Stop, Stop, Stop, Stop}}}; //WaitWTemp


void LogicAnalyzerTask(void){
  UART0_DR_R = 0x80|GPIO_PORTB_DATA_R;
	
}

int main(void){ volatile uint32_t delay;
  DisableInterrupts();
  //TExaS_Init(&LogicAnalyzerTask);
   PLL_Init();     // PLL on at 80 MHz
  SysTick_Init();   // Initialize SysTick for software waits
// **************************************************
// weird old bug in the traffic simulator
// run next two lines on real board to turn on F E B clocks
//  SYSCTL_RCGCGPIO_R |= 0x32;  // real clock register 
//  while((SYSCTL_PRGPIO_R&0x32)!=0x32){};
// run next two lines on simulator to turn on F E B clocks
  SYSCTL_RCGC2_R |= 0x32;  // LM3S legacy clock register
  delay = SYSCTL_RCGC2_R;
// **************************************************
	
	
 
  EnableInterrupts();
//	SYSCTL_RCGCGPIO_R |= 0x33;
	
	
	
	GPIO_PORTB_DIR_R |= 63;
	GPIO_PORTB_DEN_R |= 63;
	
	GPIO_PORTE_DIR_R &= ~0x07; 
	GPIO_PORTE_DEN_R |= 0x07; 
	
	GPIO_PORTF_DIR_R |= 14;
	GPIO_PORTF_DEN_R |= 14;
	uint32_t x;
	uint32_t input;
	x = GoS;
	
	
    
  while(1){
// output
		PB543210 = FSM[x].outputB;
		PF321 = FSM[x].outputF;
// wait
		SysTick_Wait10ms(FSM[x].delay);
// input
		input = PE210;
// next	
		x = FSM[x].next[input];
  }
}
