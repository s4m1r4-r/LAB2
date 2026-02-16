//***************************************************************************
/*
* LAB2.asm
*
* Creado: 07/02/2026 11:09:11
* Autor : Samira Hernández
* Descripción: Contador de 4 bist (0-F), implementado a un display de 7 segmentos ánodo, utilizando dos botones para incrementar y decrementar. 
*/
//***************************************************************************

// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PBDEF.inc"		// Include definitions specific to ATMega328P

.cseg
.org 0x00

/****************************************/
;================ STACK =================
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
/****************************************/

;================ TABLA ANODO COMUN =================
T7S:
	.DB 0x40,0x79,0x24,0x30		//0, 1, 2, 3
	.DB 0x19,0x12,0x02,0x78		//4, 5, 6, 7
	.DB 0x00,0x10,0x08,0x03		//8, 9, A, b
	.DB 0x46,0x21,0x06,0x0E		// C, d, E, F

/****************************************/
;================ SETUP =================
SETUP:

	CALL INIT_T0		//Inicialización de Timer0

	LDI R20, 0			//Contador base
	LDI R19, 0			//Contador binario
	LDI R23, 0			//Bandera alarma
	LDI R22, 15			//Máximo
	LDI R24, 0			//Mínimo 


; -------- BOTONES PB1 y PB2 --------
	LDI R16, 0b00000110
	OUT PORTB, R16

;----------PRESCALER-----------------
	LDI R16, (1<<CLKPCE)		//Permitir cambio de prescaler
	STS CLKPR, R16
	LDI R16, 0b0000_0111		; 
	STS CLKPR, R16	

; ------------- LEDs ---------------
; PD0–PD3 = LEDs contador binario
; PD6 = LED alarma
; PD7 = segmento g del display
	LDI R16, 0b11111111
	OUT DDRD, R16           // Todo PORTD como salida

; ------------- DISPLAY -------------
; PC0–PC5 = segmentos a–f
	LDI R16, 0b01111111
	OUT DDRC, R16           // Configurar como salida
	SBI DDRD, 7             // PD7 como salida (segmento g)

; ------------- PUNTERO Z DEL DISPLAY -------------
	LDI R18, 0              // Código actual del display
	LDI R21, 0              // Valor seleccionado con botones

	LDI ZH, HIGH(T7S << 1)  // Apuntar a tabla en memoria Flash
    LDI ZL, LOW(T7S << 1)
    ADD ZL, R18
    LPM R18, Z             // Cargar primer valor (0)
/****************************************/

/****************************************/
LOOP:
;================ LOOP =================
; ------------- MOSTRAR EN DISPLAY ---------------
; a–f por PORTC
	MOV R16, R18
	ANDI R16, 0b00111111
	OUT PORTC, R16

; g por PD7
	SBRC R18, 6
	SBI PORTD, 7

	SBRS R18, 6
	CBI PORTD, 7

; ------------- LECTURA BOTONES ---------------
	IN R16, PINB
	SBRS R16, 2          // Si PB2 presionado
	RJMP DB_1            // Ir a antirrebote incremento

	IN R17, PINB
	SBRS R17, 1          // Si PB1 presionado
	RJMP DB_2            // Ir a antirrebote decremento

; ------------- TIMER0 ---------------
	IN R16, TIFR0
	SBRS R16, OCF0A      // Esperar comparación
	RJMP LOOP 

	SBI TIFR0, OCF0A     // Limpiar bandera
	INC R20              // Incrementa base 100ms
	CPI R20, 1
	BRNE LOOP            // Si no llega a 1, salir

	CLR R20
	SBI PINB, 3          // Toggle prueba

; -------- BLOQUEO SI VALOR = 0 --------
TST R21                // ¿Display está en 0?
BRNE CONTAR_NORMAL

SBI PORTD, 6           // Encender LED alarma
CLR R19                // Reiniciar contador
RJMP LOOP              // No contar

CONTAR_NORMAL:
CPSE R19, R22	
CALL LEDS              // Incrementar LEDs

LDI R19, 0             // Reinicia si llegó a 15
OUT PORTD, R19

CPSE R23, R24
SBI PORTD, 6           // Activar alarma si corresponde

RJMP LOOP 
/****************************************/

/****************************************/
// SUBRUTINAS

; ------------- ANTIREBOTE ---------------
DB_1:
	LDI R16, 100
delay1:	
	DEC R16
	BRNE delay1
	SBIS PINB, 2
	RJMP DB_1
	CALL INCREMENTAR

DB_2:
	LDI R17, 100
delay2:	
	DEC R17
	BRNE delay2
	SBIS PINB, 1
	RJMP DB_2
	CALL DECREMENTAR	

; ------------- INCREMENTAR ---------------
INCREMENTAR: 
	CPSE R21, R22
	INC R21              // Aumenta valor
	MOV R18, R21

	LDI ZH, HIGH(T7S << 1)
    LDI ZL, LOW(T7S << 1)
    ADD ZL, R18
    LPM R18, Z          // Actualiza display

	RJMP LOOP 

; ------------- DECREMENTAR ---------------
DECREMENTAR: 
	CPSE R21, R24
	DEC R21              // Disminuye valor
	MOV R18, R21

	LDI ZH, HIGH(T7S << 1)
    LDI ZL, LOW(T7S << 1)
    ADD ZL, R18
    LPM R18, Z          // Actualiza display

	RJMP LOOP 

; ------------- LEDS BINARIOS ---------------
LEDS: 
	INC R19              // Incrementar contador
	LSL R19
	LSL R19
	OUT PORTD, R19       // Mostrar en PD0–PD3

	CPSE R23, R24
	SBI PORTD, 6         // Activar alarma

	LSR R19
	LSR R19

	CPSE R19, R21        // ¿Llegó al valor seleccionado?
	RJMP LOOP 

	CALL ALARMA 

; ------------- TIMER0 ---------------
Init_T0: 
	LDI R16, 0
	OUT TCNT0, R16

	LDI R16, 156
	OUT OCR0A, R16

    LDI R16, (1 << WGM01)
    OUT TCCR0A, R16      // Modo CTC

    LDI R16, (1 << CS02)|(1 << CS00)
    OUT TCCR0B, R16      // Prescaler 1024

    RET

; ------------- ALARMA ---------------
ALARMA: 
	CPSE R23, R24
	CALL APAGAR_ALARMA

	LDI R23, 15
	SBI PORTD, 6          // Encender LED alarma
	LDI R19, 15
	RJMP LOOP 

APAGAR_ALARMA: 
	LDI R23, 0 
	LDI R19, 15
	RJMP LOOP 