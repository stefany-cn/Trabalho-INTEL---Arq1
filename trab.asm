


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
file_handle		DW 0												; Handler do arquivo
count_letra    	DW -1
count_linha    	DW 1
count_word		dw -1
flag_fim_arq	DB 0
flag_inc_linha	DB 0
eol         	DB CR, LF, '$'
vet_ant      	DB 20 DUP('$')
vet_atual    	DB 20 DUP('$')
vet_prox    	DB 20 DUP('$')
word_to_find	DB 20 DUP(?)										
file_buffer		DB 20 DUP('$')
buffer_word		DB 20 DUP('$')
buffer_read  	DB 20 DUP('$')
ask_input   	DB "-- Que palavra voce quer buscar?", CR, LF, "$"
erro_abre_arq	DB "-- Erro ao abrir o arquivo", CR, LF, "$"
word_not_found	DB "-- Palavra nao encontrada!", CR, LF, "$"
word_found		DB "-- Palavra encontrada!", CR, LF, "$"
linha			DB "Linha ", "$"
dois_pontos		DB ": ", "$"
num_linha		dw 20 DUP('$')
file_name		DB "ola.txt", 0
cmd_line		DB 255 DUP(0)





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

	MOV AX, DS
	MOV ES, AX
;tira espaços do nome do arquivo
    CALL parsingNomeArq
;abre arquivo
	MOV AH, ABREARQ
	MOV AL, 0
	LEA DX, cmd_line
	INT 21H
	JNC arqAberto
;mensagem de erro ao abrir o arquivo
	MOV AH, PRINTSTR
    LEA DX, erro_abre_arq
    INT 21H	 
	JMP fim
arqAberto:
	MOV file_handle, AX
	; MOV AH, PRINTSTR
    ; LEA DX, arq_aberto
    ; INT 21H

    CALL askInput
    
    CALL readString

	MOV BX, -1
contWord:
	INC BX
	INC count_word
	CMP [word_to_find+BX], 0
	JNE contWord
	
	



leCharLoop:
	LEA DX, buffer_read
	MOV BX, file_handle   
    MOV AH, 3FH
    MOV CX, 1
    INT 21H

	MOV BX, count_letra
	INC BX
	CMP [buffer_read], ' '
	JE compara
	CMP [buffer_read], CR
	JE inc_linha
	CMP [buffer_read], LF
	JE flagFim
	OR AX, AX 
	JZ fimArq
	MOV AL, [buffer_read]
	MOV [vet_atual+BX], AL
	MOV count_letra, BX
	
	JMP leCharLoop
fimArq:
	INC flag_fim_arq
	JMP compara
inc_linha:
	INC flag_inc_linha   
compara:
	MOV count_letra, BX
	CMP BX, count_word
	JNE fimCompara
	MOV BX, -1
loopCompara:
    INC BX
	MOV AL, [vet_atual+BX]
    CMP AL, [word_to_find+BX]
    JNE fimCompara
	DEC count_letra
	CMP count_letra, 0
	JE imprime
    JMP loopCompara
fimCompara:

    MOV CX, LENGTHOF vet_atual
	LEA SI, vet_atual
	LEA DI, vet_ant
	REP MOVSB

    ; MOV AH, PRINTSTR
    ; LEA DX, vet_ant
    ; INT 21H
	MOV count_letra, -1
	CMP flag_inc_linha, 1
	JNE flagFim
	INC count_linha
	MOV [vet_ant], 0
	MOV [vet_ant+1], '$'
	DEC flag_inc_linha
flagFim:
	CMP flag_fim_arq, 1
	JE fim
	JMP leCharLoop
imprime:
	
    
    MOV AH, PRINTSTR
    LEA DX, word_found
    INT 21H
	MOV AH, PRINTSTR
    LEA DX, linha
    INT 21H

	MOV AX, count_linha
	ADD AX, '0'
	MOV num_linha, AX
	MOV AH, PRINTSTR
    LEA DX, num_linha
    INT 21H

	MOV AH, PRINTSTR
    LEA DX, dois_pontos
    INT 21H

	MOV AH, PRINTSTR
    LEA DX, vet_ant
    INT 21H
	
	MOV AH, PRINTCHAR
    mov Dl, ' '
    INT 21H

	MOV AH, PRINTSTR
    LEA DX, vet_atual
    INT 21H

	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H

	JMP leCharLoop
fim:
    .exit
;============ função para ler string do teclado (pega do moodle) =======
readString	proc	near
	PUSH DI
	PUSH SI
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
	POP SI
	POP DI
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
	MOV BX, 0
loopParsing:
	INC BX
	MOV AL, [cmd_line+BX]
	DEC BX
	MOV [cmd_line+BX], AL
	INC BX
	CMP [cmd_line+BX], ' '
	JE fimParsing
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