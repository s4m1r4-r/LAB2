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

; -------- BOTONES PB1 y PB2 --------
cbi DDRB, 1          // PB1 entrada
cbi DDRB, 2          // PB2 entrada
sbi PORTB, 1         // pull-up
sbi PORTB, 2         // pull-up

; -------- DISPLAY --------
ldi R16, 0b00111111
out DDRC, R16        // PC0–PC5 salida (a–f)

sbi DDRD, 7          // PD7 salida (g)

; -------- VARIABLE --------
ldi R19, 0           // contador incialmente en 0
/****************************************/

/****************************************/
;================ LOOP =================
LOOP:

; Cargar valor de tabla
mov R18, R19		//Copiar contador 
ldi ZH, HIGH(T7S<<1)	//Apuntar en tabla de memoria
ldi ZL, LOW(T7S<<1)
add ZL, R18			//Desplazar según número
lpm R18, Z			//Leer valor tabla

; Mostrar a–f en PORTC
out PORTC, R18

; Mostrar segmento g (bit6)
sbrc R18, 6		//Bit6 = 1
sbi PORTD, 7	//Apagar segmento g

sbrs R18, 6		//Bit6 = 0
cbi PORTD, 7	//Encender segmento g

; -------- Leer botones --------
in R16, PINB		//Lee el estado del puerto B

; Botón PB2 = 0 (botón presionado) - Incrementa
sbrs R16, 2
rjmp DB_INC

; Botón PB1 = 0 (botón presionado) - Decrementar
sbrs R16, 1
rjmp DB_DEC

rjmp LOOP
/****************************************/

/****************************************/
// NON-Interrupt subroutines

;================ ANTIREBOTE + INC =================

DB_INC:
ldi R16, 100	// Retardo
D1:
dec R16
brne D1

sbis PINB, 2	//Verifica si aún esta presionado
rjmp DB_INC

inc R19		//Incrementa el contador 
andi R19, 0x0F		//Limitar de 0 a F
rjmp LOOP

;================ ANTIREBOTE + DEC =================
DB_DEC:
ldi R16, 100		//Retardo
D2:
dec R16
brne D2

sbis PINB, 1	//Verifica si esta presionado
rjmp DB_DEC

dec R19		//Decrementa el contador
andi R19, 0x0F		//Limita de 0 a F
rjmp LOOP
/****************************************/