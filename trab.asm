


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

resp			DB ?
resto			DB ?
quociente		DB ?
flag_sim		DB 0
flag_resp		DB 0
flag_igual		DB 0
file_handle		DW 0										; Handler do arquivo
indice_word		DW 0
flag_fim_arq	DB 0
flag_inc_linha	DB 0
flag_encontrou	DB 0
flag_nova_busca DB 0
count_linha    	DW 1
indice			DW -1
tam_word		DW -1
tam_vetAt		DW -1
tam_vetAt2		DW -1
count_letra    	DW -1
word_to_find	DB 20 DUP(?)
word_toUpper	DB 20 DUP(?)
vazio			DB 20 DUP (0)
cmd_line		DB 20 DUP (0)
vet_ant      	DB 20 DUP('$')
num_linha		DB 20 DUP('$')
vet_atual    	DB 20 DUP('$')
buffer_word		DB 20 DUP('$')
buffer_read  	DB 20 DUP('$')
vet_atualUpper 	DB 20 DUP('$')
eol         	DB CR, LF, "$"
encerrando		DB "-- Encerrando.", CR, LF, "$"
word_found		DB "-- Fim das ocorrencias.", CR, LF, "$"
erro_abre_arq	DB "-- Erro ao abrir o arquivo", CR, LF, "$"
sim_nao			DB "-- Por favor, responda somente S ou N.", "$"
ask_input   	DB "-- Que palavra voce quer buscar?", CR, LF, "$"
outra_palavra?	DB "-- Quer buscar outra palavra? (S/N)", CR, LF, "$"
word_not_found	DB "-- Nao foram encontradas ocorrencias.", CR, LF, "$"
pontuacao		DB "-- Nao e permitida pontuacao e acentuacao.", CR, LF, "$"
linha			DB "Linha ", "$"
dois_pontos		DB ": ", "$"
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
inicioProg:
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
	
;inicializando variaveis e flags

	MOV flag_encontrou, 0
	MOV flag_fim_arq, 0
	MOV flag_igual, 0
	MOV flag_inc_linha, 0
	MOV flag_resp, 0
	MOV flag_sim, 0
	
	MOV tam_word, -1
	MOV tam_vetAt, -1
	MOV count_linha, 1

	MOV quociente, 0
	MOV resto, 0
	MOV indice, -1

	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, num_linha
	REP MOVSB

	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, vet_ant
	REP MOVSB
	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, vet_atual
	REP MOVSB
	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, vet_atualUpper
	REP MOVSB
	JMP pedePalavra

pedePalavra2:
	MOV AH, PRINTSTR
    LEA DX, pontuacao
    INT 21H
pedePalavra:
    CALL askInput
    
    CALL lePalavraInput
	MOV BX, -1
	MOV tam_word, -1
contWord:
	INC BX
	INC tam_word
	CMP [word_to_find+BX], 0
	JNE contWord

	MOV flag_nova_busca, 0
	CALL validaBusca
	CMP flag_nova_busca, 0
	JNE pedePalavra2



voltaDeNaoAchou:
	CMP flag_fim_arq, 1
	JE naoEncontrou
	;coloca espaço em todo vetor da palavra anterior
	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, vet_ant
	REP MOVSB
	;coloca a palavra atual no vetor da palavra anterior
    MOV CX, LENGTHOF vet_atual
	LEA SI, vet_atual
	LEA DI, vet_ant
	REP MOVSB

	CMP flag_inc_linha, 1
	JNE pulaIncLinha
	DEC flag_inc_linha
	INC count_linha
pulaIncLinha:
	CALL lePalavraArq
voltaDeAchou:
	
	CALL comparaPalavra
	CMP flag_igual, 1
	JNE voltaDeNaoAchou
	
	CALL imprime
	CMP flag_fim_arq, 1
	JNE voltaDeAchou
naoEncontrou:
	CMP flag_encontrou, 0
	JNE encontrou

	MOV AH, PRINTSTR
    LEA DX, word_to_find
    INT 21H
	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H

	MOV AH, PRINTSTR
    LEA DX, word_not_found
    INT 21H
	JMP continuar?

encontrou:
	MOV AH, PRINTSTR
    LEA DX, word_found
    INT 21H
continuar?:
	;fecha arquivo
	MOV AH, FECHAARQ
	MOV BX, file_handle
	INT 21H

	MOV flag_resp, 0

	CALL leResposta
	CMP flag_sim, 1
	JE inicioProg

	MOV AH, PRINTSTR
    LEA DX, encerrando
    INT 21H

fim:
    .exit
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
	POP AX
	POP BX
	
	RET
parsingNomeArq ENDP
;------------- fim func parsing -----------------
;------------- inicio func printar pedido de input -----------------
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
;------------- fim func printar pedido de input -----------------
;------------- inicio func pega palavra a ser procurada -----------------
lePalavraInput	PROC NEAR
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
lePalavraInput	ENDP
;------------- fim func pega palavra a ser procurada -----------------
validaBusca PROC NEAR
	MOV BX, -1
	MOV CX, tam_word
	DEC CX
	MOV indice_word, CX
inicioValida:
	INC BX
	CMP [word_to_find+BX], 'A'
	JL pedeNovaPalavra
	CMP [word_to_find+BX], 'z'
	JG pedeNovaPalavra
	CMP [word_to_find+BX], 90
	JG verifica1
	CMP [word_to_find+BX], 97
	JL verifica2
	JMP fimValidaBusca
pedeNovaPalavra:
	INC flag_nova_busca
	JMP fimValidaBusca
verifica1:
	CMP [word_to_find+BX], 97
	JL pedeNovaPalavra
	CMP indice_word, BX
	JE fimValidaBusca
	JMP inicioValida
verifica2:
	CMP [word_to_find+BX], 90
	JG pedeNovaPalavra
	CMP indice_word, BX
	JE fimValidaBusca
	JMP inicioValida
fimValidaBusca:
	RET
validaBusca ENDP
;------------- inicio func le palavra do arquivo -----------------
lePalavraArq PROC NEAR
leCharLoop1:
	LEA DX, buffer_read
	MOV BX, file_handle  
    MOV AH, 3FH
    MOV CX, 1
    INT 21H

	MOV BX, count_letra
	INC BX
	CMP [buffer_read], ' '
	JE fimLePalavra
	CMP [buffer_read], CR
	JE flagIncLinha
	CMP [buffer_read], LF
	JE anteriorEraCR
	OR AX, AX 
	JZ fimArq
	MOV AL, [buffer_read]
	MOV [vet_atual+BX], AL
	MOV [vet_atual+BX+1], 0
	MOV [vet_atual+BX+2], '$'
	MOV count_letra, BX
	JMP leCharLoop1
anteriorEraCR:
	MOV [vet_atual], '$'
	;MOV [vet_atual+1], 
	JMP fimLePalavra
fimArq:
	MOV flag_fim_arq, 1
	JMP fimLePalavra
flagIncLinha:
	INC flag_inc_linha
fimLePalavra:
	MOV count_letra, -1
	RET
lePalavraArq ENDP
;------------- fim func le palavra do arquivo -----------------
;------------- inicio func compara palavras -----------------
comparaPalavra PROC NEAR
	CALL toUpper
	CALL toUpperVetAtual
contVetAtual:
	MOV BX, tam_vetAt
	INC BX
	INC tam_vetAt
	CMP [vet_atualUpper+BX], 0
	JNE contVetAtual

	CMP BX, tam_word
	JNE fimComparaPalavra

	MOV BX, -1
loopCompara:
    INC BX
	MOV AL, [vet_atualUpper+BX]
    CMP AL, [word_toUpper+BX]
    JNE fimComparaPalavra
	DEC tam_vetAt
	CMP tam_vetAt, 0
	JE flagIgual
    JMP loopCompara
flagIgual:
	INC flag_igual
fimComparaPalavra:
	MOV tam_vetAt, -1
	RET
comparaPalavra ENDP
;------------- fim func compara palavras -----------------
;------------- inicio func imprime -----------------
imprime PROC NEAR
	INC flag_encontrou
	;seta flag de igual para zero
	MOV flag_igual, 0
	
	;printa palavra "Linha"
	MOV AH, PRINTSTR
    LEA DX, linha
    INT 21H
	;printa o número da linha
	CALL intToStr
	MOV AH, PRINTSTR
    LEA DX, num_linha
    INT 21H
	;printa ":"
	MOV AH, PRINTSTR
    LEA DX, dois_pontos
    INT 21H
	;printa palavra anterior
	MOV AH, PRINTSTR
    LEA DX, vet_ant
    INT 21H
	;printa espaço
	MOV AH, PRINTCHAR
    mov Dl, ' '
    INT 21H

	CALL toUpperVetAtual 
	;printa palavra encontrada maiuscula
	MOV AH, PRINTSTR
    LEA DX, vet_atualUpper
    INT 21H

	;printa espaço
	MOV AH, PRINTCHAR
    mov Dl, ' '
    INT 21H
	;coloca espaço em todo vetor da palavra anterior
	MOV CX, LENGTHOF vazio
	LEA SI, vazio
	LEA DI, vet_ant
	REP MOVSB
	;coloca a palavra atual no vetor da palavra anterior
    MOV CX, LENGTHOF vet_atual
	LEA SI, vet_atual
	LEA DI, vet_ant
	REP MOVSB
	;le proxima palavra
	CALL lePalavraArq
	CMP flag_fim_arq, 1
	JE pulaVetProx
	;printa a proxima palavra
	MOV AH, PRINTSTR
    LEA DX, vet_atual
    INT 21H
pulaVetProx:
	;printa fim de linha
	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H
	;MOV count_letra, -1
	RET
imprime ENDP
leResposta PROC NEAR
inicioLeResp:
	MOV AH, PRINTSTR
    LEA DX, outra_palavra?
    INT 21H

	MOV AH, 01H
    INT 21H
	MOV resp, AL
	MOV AH, 01H
    INT 21H

	CMP resp, 'S'
	JE sim
	CMP resp, 's'
	JE sim
	CMP resp, 'N'
	JE fimleResposta
	CMP resp, 'n'
	JE fimleResposta

	

	MOV AH, PRINTSTR
    LEA DX, sim_nao
    INT 21H
	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H

	JMP inicioLeResp
sim:
	INC flag_sim
fimleResposta:
	RET
leResposta ENDP

toUpperVetAtual PROC NEAR
	MOV tam_vetAt2, -1
contVetAtual2:
	MOV BX, tam_vetAt2
	INC BX
	INC tam_vetAt2
	CMP [vet_atual+BX], 0
	JNE contVetAtual2

	MOV BX, -1
loopUpper:
	INC BX
	CMP [vet_atual+BX], 'a'
	Jl copia
	CMP [vet_atual+BX], 'z'
	Jg copia
	MOV AL, [vet_atual+BX]
	SUB AL, 20h
	MOV [vet_atualUpper+BX], AL
	DEC tam_vetAt2
	CMP tam_vetAt2, 0
	JE fimToUpper
	JMP loopUpper
copia:
	MOV AL, [vet_atual+BX]
	MOV [vet_atualUpper+BX], AL
	DEC tam_vetAt2
	CMP tam_vetAt2, 0
	JNE loopUpper
fimToUpper:
	MOV [vet_atualUpper+BX+1], 0
	MOV [vet_atualUpper+BX+2], '$'
	RET
toUpperVetAtual ENDP

toUpper PROC NEAR

	MOV BX, -1
loopUpper2:
	INC BX
	CMP [word_to_find+BX], 'a'
	Jl copia2
	CMP [word_to_find+BX], 'z'
	Jg copia2
	MOV AL, [word_to_find+BX]
	SUB AL, 20h
	MOV [word_toUpper+BX], AL
	CMP BX, tam_word
	JE fimToUpper2
	JMP loopUpper2
copia2:
	MOV AL, [word_to_find+BX]
	MOV [word_toUpper+BX], AL
	CMP BX, tam_word
	JNE loopUpper2
fimToUpper2:
	MOV [word_toUpper+BX+1], 0
	MOV [word_toUpper+BX+2], '$'
	RET
toUpper ENDP

intToStr PROC NEAR
	MOV AX, count_linha
	MOV resto, AL

	MOV indice, -1
	CMP resto, 100
	JL dezena
	MOV AX, 0
	MOV AL, resto
	MOV BL, 100
	DIV BL
	MOV quociente, AL
	MOV resto, AH
	MOV BX, indice
	INC BX
	ADD AL, '0'
	MOV [num_linha+BX], AL
	MOV indice, BX
dezena:
	CMP resto, 10
	JL unidade
	MOV AX, 0
	MOV AL, resto
	MOV BL, 10
	DIV BL
	MOV quociente, AL
	MOV resto, AH
	MOV BX, indice
	INC BX
	ADD AL, '0'
	MOV [num_linha+BX], AL
	MOV indice, BX
unidade:

	MOV BX, indice
	INC BX
	MOV AH, resto
	ADD AH, '0'
	MOV [num_linha+BX], AH
	MOV indice, BX
	MOV[num_linha+BX+1], '$'
	
	RET
intToStr ENDP

end