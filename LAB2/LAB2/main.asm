/*
* LAB2.asm
*
Created: 07/02/2026 19:17:14 
* Autor : Samira Hernández
* Descripción: 
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PBDEF.inc"     // Include definitions specific to ATMega328P


.cseg
.org 0x0000

//Registros 
.def contador1 = R17
.def cris = R18
.def delay1 = R19
.def delay2 = R20
.def temp = R21
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/

// Configuracion MCU
SETUP:
    ;LEDs (A0-A3)-Configurados como salidas
	LDI R16,0b00001111
	OUT DDRC, R16

	;Configuración de Botones
	CBI DDRB, 0
	CBI DDRB, 1

	;Activación de Pull-up interno
	SBI DDRB, 0
	SBI DDRB, 1

	;Display 
	LDI temp, 0xFF
	OUT DDRD, temp 

	CLR contador1
	CLR cris

	;Configuración de Timer0
	LDI R16, 0x00
	OUT TCCR0A, R16

	;Configuración de Prescaler 1024
	LDI R16, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R16




/****************************************/
// Loop Infinito
MAIN_LOOP:
	

    LDI R16, 0x00
	OUT TCNT0, R16

	;Mostrar el número actual 
	RCALL MOSTRAR

	;Lectura de PINB
	IN temp, PINB 

	;-----------BOTÓN INCREMENTO---------------
	SBRS temp, 0
	RCALL INCREMENTAR

	;---------BOTÓN DECREMENTAR----------------
	SBRS temp, 1
	RCALL DECREMENTAR

	RJMP MAIN

/****************************************/
// NON-Interrupt subroutines

PAUSA: 
	IN R16, TIFR0		//lee registro de bandera TIMER0
	SBRS R16, TOV0		//Verifica si hubo overflow
	RJMP PAUSA			

	LDI R16, (1<<TOV0)	// Si hubo overflow, limpiar bandera
	OUT TIFR0, R16

	INC cris
	CPI cris, 6
	BRNE MAIN_LOOP

	CLR cris

	INC contador1
	ANDI contador1, 0x0F

	MOV R16, contador1
	OUT PORTC, R16
	RJMP MAIN_LOOP

;DISPLAY
MOSTRAR: 
	LDI ZH, HIGH(TABLA<<1)
	LDI ZL, LOW(TABLA<<1)
	ADD ZL, contador1
	LPM temp, Z
	OUT PORTD, temp 
	RET

;-----------INCREMENTO--------------
	RCALL ANTIREBOTE
	INC CONTADOR

/****************************************/
// Interrupt routines

/****************************************/