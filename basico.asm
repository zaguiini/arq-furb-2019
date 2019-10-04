	; I/O Address Bus decode - every device gets 0x200 addresses */

	IO0  EQU  0000h
	IO1  EQU  0200h
	IO2  EQU  0400h
	IO3  EQU  0600h
	IO4  EQU  0800h
	IO5  EQU  0A00h
	IO6  EQU  0C00h
	IO7  EQU  0E00h
	IO8  EQU  1000h
	IO9  EQU  1200h
	IO10 EQU  1400h
	IO11 EQU  1600h
	IO12 EQU  1800h
	IO13 EQU  1A00h
	IO14 EQU  1C00h
	IO15 EQU  1E00h

	TAM_STRING EQU 200

	CODE  SEGMENT 
		  ASSUME DS:DATA
		  org 0000h

	;MEU CODIGO
	inicio:
		MOV AX,DATA
		MOV DS,AX   ; DS AGORA APONTA PARA DATA SEGMENT
		MOV AX,EXTRA
		MOV ES,AX   ; ES AGORA APONTA PARA EXTRA SEGMENT
		MOV AX,STACK
		MOV SS,AX   ; SS AGORA APONTA PARA STACK SEGMENT

		CALL INICIALIZA_8251
		
		MOV BX, OFFSET MENSAGEM_INICIAL
		CALL MANDA_MENSAGEM
		
	REPETE:
		JMP REPETE


MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX  ; SALVA AL   
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX  ; RESTAURA AL
   OUT DX,AL
   POP DX
   POPF
   RET 

MANDA_MENSAGEM:
	PUSHF
	PUSH AX
	INC BX ; PULA TAMANHO DA MENSAGEM
MANDA_MENSAGEM_CARACTER:
	MOV AL,[BX]
	CMP AL,0
	JE FIM_MANDA_MENSAGEM
	CALL MANDA_CARACTER
	INC BX
	JMP MANDA_MENSAGEM_CARACTER
FIM_MANDA_MENSAGEM:
	POP AX
	POPF
	RET



; 8251A USART 

ADR_USART_DATA EQU  (IO4 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO4 + 02h)
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO4 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

INICIALIZA_8251:                                     
   MOV AL,0
   MOV DX, ADR_USART_CMD
   OUT DX,AL
   OUT DX,AL
   OUT DX,AL
   MOV AL,40H
   OUT DX,AL
   MOV AL,4DH
   OUT DX,AL
   MOV AL,37H
   OUT DX,AL
   RET


	CODE ENDS

	;MILHA PILHA
	STACK SEGMENT STACK      
	DW 128 DUP(?) 
	STACK ENDS 

	;MEUS DADOS
	DATA      SEGMENT
	
	MENSAGEM_INICIAL DB ?, "FORCA", 13, 10, "ENTRE COM UMA PALAVRA", 13, 10, 0

	DATA 	  ENDS
	

	;EXTRA

	EXTRA SEGMENT
	EXTRA ENDS

	end inicio
