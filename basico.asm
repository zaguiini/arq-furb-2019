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

   org 0008h
   DW OFFSET RELOGIO

   org 0400h

   ;MEU CODIGO
   inicio:
      MOV AX,DATA
      MOV DS, AX   ; DS AGORA APONTA PARA DATA SEGMENT
      MOV AX,EXTRA
      MOV ES, AX   ; ES AGORA APONTA PARA EXTRA SEGMENT
      MOV AX,STACK
      MOV SS, AX   ; SS AGORA APONTA PARA STACK SEGMENT

      CALL INICIALIZA_8251

      MOV BX, OFFSET MENSAGEM_INICIAL
      CALL MANDA_MENSAGEM

      MOV BX, OFFSET PALAVRA_A_SER_DECIFRADA
      INC DEVE_ESCONDER
      CALL RECEBE_MENSAGEM
      DEC DEVE_ESCONDER
      
      CALL PULA_LINHA
      CALL PULA_LINHA
      
      CALL AJUSTA_PARCIAL

      ADIVINHA_PALAVRA:
	 CALL CHECA_VENCEDOR
	 CMP JA_VENCEU, 1
	 JE FIM_DE_JOGO
	 
	 MOV BX, OFFSET MENSAGEM_AGUARDANDO_LETRA
	 CALL MANDA_MENSAGEM
      
	 MOV BX, OFFSET LETRA_ATUAL
	 CALL RECEBE_MENSAGEM
	 
	 ;LOGICA PRA CHECAR LETRA COM PALAVRA
      
	 CALL PULA_LINHA
	 
	 JMP ADIVINHA_PALAVRA

      FIM_DE_JOGO:
	 CALL PULA_LINHA
	 
	 MOV BX, OFFSET MENSAGEM_FIM
         CALL MANDA_MENSAGEM
      
      REPETE:
         JMP REPETE

AJUSTA_PARCIAL:
   PUSHF
   POPF
   RET

CHECA_VENCEDOR:
   PUSHF
   PUSH AX
   PUSH BX
   MOV BX, OFFSET PALAVRA_PARCIAL
   INC BX
CHECA_VENCEDOR_WHILE:
   MOV AL, [BX]
   CMP AL, 0
   JE SAI_CHECA_VENCEDOR
   CMP AL, '_'
   JE AINDA_NAO_VENCEU
   INC BX
   JMP CHECA_VENCEDOR_WHILE
AINDA_NAO_VENCEU:
   MOV JA_VENCEU, 0
   POP BX
   POP AX
   POPF
   RET
SAI_CHECA_VENCEDOR:
   MOV JA_VENCEU, 1
   POP BX
   POP AX
   POPF
   RET
   
MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX  ; SALVA AL   
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL, DX
   TEST AL, 1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX  ; RESTAURA AL
   OUT DX, AL
   POP DX
   POPF
   RET 

MANDA_MENSAGEM:
   PUSHF
   PUSH AX
   INC BX ; PULA TAMANHO DA MENSAGEM
MANDA_MENSAGEM_CARACTER:
   MOV AL, [BX]
   CMP AL, 0
   JE FIM_MANDA_MENSAGEM
   CALL MANDA_CARACTER
   INC BX
   JMP MANDA_MENSAGEM_CARACTER
FIM_MANDA_MENSAGEM:
   POP AX
   POPF
   RET

RECEBE_CARACTER:
   PUSHF
   PUSH DX
AGUARDA_CARACTER:
   MOV DX, ADR_USART_STAT
   IN  AL, DX
   TEST AL, 2
   JZ AGUARDA_CARACTER
   MOV DX, ADR_USART_DATA
   IN AL, DX
   SHR AL,1
NAO_RECEBIDO:
   POP DX
   POPF
   RET

RECEBE_MENSAGEM:
   PUSHF
   PUSH AX
   INC BX ; APONTE PARA O PAYLOAD, NAO APONTE PARA O TAMANHO
   MOV CONTADOR_LETRAS, 0
RECEBE_MENSAGEM_CARACTER:
   CALL RECEBE_CARACTER
   CMP AL, 13
   JE SAI_RECEBE_CARACTER
   CMP AL, 8  ; BACKSPACE
   JE CONSISTE_BACKSPACE
   CMP CONTADOR_LETRAS,TAM_STRING
   JE RECEBE_MENSAGEM_CARACTER
   CMP AL, 'a'
   JL GUARDA_CARACTER
   CMP AL, 'z'
   JG GUARDA_CARACTER
   SUB AL, 32
GUARDA_CARACTER:
   MOV [BX],AL
   CMP DEVE_ESCONDER, 1
   JE ESCONDE
   JMP IMPRIME_CARACTER
ESCONDE:
   MOV AL, '*'
IMPRIME_CARACTER:
   CALL MANDA_CARACTER
   INC BX
   INC CONTADOR_LETRAS
   JMP RECEBE_MENSAGEM_CARACTER
CONSISTE_BACKSPACE:
   CMP CONTADOR_LETRAS, 0
   JE  RECEBE_MENSAGEM_CARACTER
   DEC BX
   DEC CONTADOR_LETRAS
   CALL MANDA_CARACTER ; EXCLUSIVO PARA IMPRIMIR BACKSPACE
   JMP RECEBE_MENSAGEM_CARACTER
SAI_RECEBE_CARACTER:
   MOV AL, 0
   MOV [BX], AL
   MOV BL, CONTADOR_LETRAS ; APONTA PARA CAMPO TAMANHO DE TEXTO
   MOV AL, CONTADOR_LETRAS ; PEGA
   MOV [BX], AL
   POP AX
   POPF
   RET

PULA_LINHA:
   PUSHF
   PUSH AX
   MOV AL, 13
   CALL MANDA_CARACTER
   MOV AL, 10
   CALL MANDA_CARACTER
   POP AX
   POPF
   RET

RELOGIO:
   PUSHF	
   INC SEGUNDOS_UNID
   CMP SEGUNDOS_UNID, 10
   JE ZERA_SEGUNDOS_UNID
   JMP SAI_INTERRUPT_RELOGIO
ZERA_SEGUNDOS_UNID:
   MOV SEGUNDOS_UNID, 0
   INC SEGUNDOS_DEZ
   CMP SEGUNDOS_DEZ, 6
   JE ZERA_SEGUNDOS_DEZ
   JMP SAI_INTERRUPT_RELOGIO	 
ZERA_SEGUNDOS_DEZ:
   MOV SEGUNDOS_DEZ, 0		
SAI_INTERRUPT_RELOGIO:
   POPF
   IRET

   ; 8251A USART 

ADR_USART_DATA EQU  (IO4 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO4 + 02h)
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO4 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

INICIALIZA_8251:                                     
   MOV AL, 0
   MOV DX, ADR_USART_CMD
   OUT DX, AL
   OUT DX, AL
   OUT DX, AL
   MOV AL, 40H
   OUT DX, AL
   MOV AL, 4DH
   OUT DX, AL
   MOV AL, 37H
   OUT DX, AL
   RET

CODE ENDS

;MILHA PILHA
STACK SEGMENT STACK  
    
   DW 128 DUP(?)

STACK ENDS 

;MEUS DADOS
DATA SEGMENT

   CONTADOR_LETRAS DB 0
   SEGUNDOS_UNID DB 0
   SEGUNDOS_DEZ DB 0
   DEVE_ESCONDER DB 0
   JA_VENCEU DB 0

   MENSAGEM_INICIAL DB ?, "FORCA", 13, 10, "ENTRE COM UMA PALAVRA", 13, 10, 0
   MENSAGEM_AGUARDANDO_LETRA DB ?, "ENTRE COM UMA LETRA: ", 0
   MENSAGEM_FIM DB ?, "PARABENS VOCE GANHOU", 0

   PALAVRA_A_SER_DECIFRADA DB ?, TAM_STRING + 1 DUP(?)
   LETRA_ATUAL DB 1, ?, 0
   PALAVRA_PARCIAL DB ?, TAM_STRING + 1 DUP("_")
 
DATA ENDS


;EXTRA

EXTRA SEGMENT
EXTRA ENDS

end inicio
