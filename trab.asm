;=============================================
;       FUNCIONANDO ATÉ PEGAR A STRING!
;               NÃO MODIFICAR
;=============================================


CR          EQU 0DH
LF          EQU 0AH
BS          EQU 08H
SPACE       EQU 20H
ABREARQ     EQU 3DH
LEARQ       EQU 3FH
FECHAARQ    EQU 3EH
PRINTCHAR   EQU 02H
PRINTSTR    EQU 09H
LESTR       EQU 0AH

 
.model small
.stack

.data
cmd_line		DB ?
eol         	DB CR, LF, '$'
vet_ant      	DB ?
vet_atual    	DB ?
vet_prox    	DB ?
count_lin    	DB 0
ask_input   	DB "-- Que palavra voce quer buscar?", CR, LF, "$"
word_to_find	DB ?		; Nome do arquivo a ser lido
file_buffer		DB ?
file_handle		DW 0		; Handler do arquivo
buffer_word		DB ?
buffer_read  	DB ?
erro_abre_arq	DB "-- Erro ao abrir o arquivo", CR, LF, "$"
arq_aberto		DB "-- Arquivo aberto", CR, LF, "$"
file_name		DB "ola.txt", "$"

.code

    .startup
	PUSH DS 			; Salva as informacoes de segmentos
	PUSH ES
	
	MOV AX, DS			; Troca DS com ES para poder usa o REP MOVSB
	mov bx, es
	mov ds, bx
	mov es, ax
	mov si, 80h 		; Obtem o tamanho da linha de comando e coloca em CX
	mov ch, 0
	mov cl, [si]
	mov ax, cx 			; Salva o tamanho do string em AX, para uso futuro
	mov si, 81h 		; Inicializa o ponteiro de origem
	lea di, cmd_line 	; Inicializa o ponteiro de destino
	rep movsb
	
	POP ES 				; retorna os dados dos registradores de segmentos
	POP DS

;tira espaços do nome do arquivo
    CALL parsingNomeArq
;abre arquivo
	MOV AH, ABREARQ
	MOV AL, 0
	LEA DX, cmd_line
	INT 21H
	JNC arqAberto
	MOV AH, PRINTSTR
    LEA DX, erro_abre_arq
    INT 21H	 
	JMP fim
arqAberto:
	; MOV AH, PRINTSTR
    ; LEA DX, arq_aberto
    ; INT 21H

    ;CALL askInput
    
    ;CALL readString
fim:
    .exit
;============ função para ler string do teclado (pega do moodle) =======
readString	proc	near
    MOV AH, LESTR
    LEA DX, buffer_word
    MOV byte ptr buffer_word, 20
    INT 21H
    
    LEA SI, buffer_word+2
    LEA DI, word_to_find
    MOV CL, buffer_word+1
    MOV CH, 0
    MOV AX, DS
    MOV ES, AX
    REP MOVSB
    
	MOV	byte ptr ES:[DI], 0
    MOV	byte ptr ES:[DI+1], '$'
	RET

readString	endp
;------------------ inicio func print string -----------------
printString	proc	near
	MOV AH, PRINTSTR
    LEA DX, word_to_find
    INT 21H	
	RET
printString	endp
;-------------- fim print string -------------------
;-------------- inicio func parsing-----------------
parsingNomeArq PROC NEAR
	PUSH BX				;SALVA CONTEXTO
	PUSH AX
inicParsing:
	CMP [cmd_line], ' '	;COMPARA PRIMEIRA POSIÇÃO COM ESPAÇO
	JNE fimParsing
	MOV BX, -1
loopParsing:
	INC BX
	CMP BX, 0
	JZ firstParsing
	CMP [cmd_line+BX], ' '
	JE fimParsing
firstParsing:
	MOV AL, [cmd_line+BX]
	DEC BX
	MOV [cmd_line+BX], AL
	INC BX
	JMP loopParsing
fimParsing:
	MOV AL, 0
	MOV [cmd_line+BX], AL
	;INC BX
	;MOV [cmd_line+BX], '$'
	POP AX
	POP BX
	
	RET
parsingNomeArq ENDP

askInput PROC NEAR
    PUSH AX
    PUSH DX
    
    MOV AH, 09H
    LEA DX, ask_input
    INT 21H
    
    POP DX
    POP AX
    RET
askInput ENDP 

end