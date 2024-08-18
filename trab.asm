;------------------------------------------------------------------------------------------------------------
; 										DECLARAÇÃO DE CONSTANTES
;------------------------------------------------------------------------------------------------------------

CR          EQU 0DH
LF          EQU 0AH
ABREARQ     EQU 3DH
LEARQ       EQU 3FH
FECHAARQ    EQU 3EH
PRINTCHAR   EQU 02H
PRINTSTR    EQU 09H
LESTR       EQU 0AH
;------------------------------------------------------------------------------------------------------------
; 									   FIM DECLARAÇÃO DE CONSTANTES
;------------------------------------------------------------------------------------------------------------
 
.model small
.stack
;------------------------------------------------------------------------------------------------------------
; 											DATA SEGMENT
;------------------------------------------------------------------------------------------------------------
.data


resto			DB ?
quociente		DB ?
flag_sim		DB 0
flag_resp		DB 0
flag_igual		DB 0
file_handle		DW 0										; Handler do arquivo
indice_word		DW 0
flag_passou		DB 0
flag_fim_arq	DB 0
flag_inc_linha	DB 0
flag_encontrou	DB 0
flag_nova_busca DB 0
flag_pontoVirg	DB 0
count_linha    	DW 1
indice			DW -1
tam_word		DW -1
tam_vetAt		DW -1
tam_vetAt2		DW -1
count_letra    	DW -1
resp			DB 2 DUP(?)
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
encerrando		DB "-- Encerrando.", "$"
word_found		DB "-- Fim das ocorrencias.", CR, LF, "$"
erro_abre_arq	DB "-- Erro ao abrir o arquivo", CR, LF, "$"
sim_nao			DB "-- Por favor, responda somente S ou N.", "$"
ask_input   	DB "-- Que palavra voce quer buscar?", CR, LF, "$"
outra_palavra?	DB "-- Quer buscar outra palavra? (S/N)", CR, LF, "$"
word_not_found	DB "-- Nao foram encontradas ocorrencias.", CR, LF, "$"
pontuacao		DB "-- Nao e permitida pontuacao e acentuacao.", CR, LF, "$"
encontradas		DB "-- Foram encontradas as seguintes ocorrencias:", CR, LF, "$"
linha			DB "Linha ", "$"
dois_pontos		DB ": ", "$"

;------------------------------------------------------------------------------------------------------------
; 											END DATA SEGMENT
;------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------
; 											CODE SEGMENT
;------------------------------------------------------------------------------------------------------------
.code
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;											INICIO MAIN
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    .startup
;--- Pega nome do arquivo a ser lido da linha de comando ----
	PUSH DS 			; Salva as informacoes de segmentos
	PUSH ES
	
	MOV AX, DS			; Troca DS com ES para poder usa o REP MOVSB
	MOV BX, ES
	MOV DS, BX
	MOV ES, AX
	MOV SI, 80H 		; Obtem o tamanho da linha de comando e coloca em CX
	MOV CH, 0
	MOV CL, [SI]
	MOV AX, CX 			; Salva o tamanho do string em AX, para uso futuro
	MOV SI, 81H 		; Inicializa o ponteiro de origem
	LEA DI, CMD_LINE 	; Inicializa o ponteiro de destino
	REP MOVSB
	
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
;fim das inicializações
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
;calcula o tamanho da palavra a ser buscada
	INC BX
	INC tam_word
	CMP [word_to_find+BX], 0
	JNE contWord

	MOV flag_nova_busca, 0

	CALL validaBusca

	CMP flag_nova_busca, 0
	JNE pedePalavra2



voltaDiferentes:
;se as palavras são diferentes
	CMP flag_fim_arq, 1							;verifica se chegou ao final do arquivo
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

	CMP flag_inc_linha, 1						;verifica se teve CR durante a leitura da palavra do arquivo
	JNE pulaIncLinha
	DEC flag_inc_linha
	INC count_linha
pulaIncLinha:
	;le palavra do arquivo
	CALL lePalavraArq							
voltaDeAchou:
	
	CALL comparaPalavra
	CMP flag_igual, 1
	JNE voltaDiferentes

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
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;												FIM MAIN
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;=====================  INICIO FUNC PARA TIRAR ESPAÇOS DO NOME DO ARQUIVO  =============================
parsingNomeArq PROC NEAR
	PUSH BX						;salva contexto
	PUSH AX
inicParsing:
	CMP [cmd_line], ' '			;compara a primeira posição com espaço
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
;=====================  FIM FUNC PARA TIRAR ESPAÇOS DO NOME DO ARQUIVO  ===============================

;=======================  INICIO FUNC PARA PRINTAR PERGUNTA DE INPUT  =================================
askInput PROC NEAR
    PUSH AX
    PUSH DX
    
    MOV AH, PRINTSTR
    LEA DX, ask_input
    INT 21H
    
    POP DX
    POP AX
    RET
askInput ENDP 
;=======================	FIM FUNC PARA PRINTAR PERGUNTA DE INPUT  =================================

;=====================	INICIO FUNC PARA PEGAR PALAVRA A SER PROCURADA  ==============================
;esta função foi pega do moodle e acredito que tenha sido elaborada pelo professor Sergio Cecchin
	;apenas alterei nomes de variáveis
lePalavraInput	PROC NEAR
	PUSH DI							;guardando contexto
	PUSH SI

    MOV AH, LESTR
    LEA DX, buffer_word
    MOV byte ptr buffer_word, 20	;le até 20 caracteres (contando CR)
    INT 21H
    ;transfere os dados de um vetor para outro 
    LEA SI, buffer_word+2
    LEA DI, word_to_find
    MOV CL, buffer_word+1
    MOV CH, 0
    MOV AX, DS
    MOV ES, AX
	
    REP MOVSB
    
	MOV	byte ptr ES:[DI], 0
    MOV	byte ptr ES:[DI+1], '$'

	POP SI							;devolvendo contexto
	POP DI
	RET
lePalavraInput	ENDP
;=====================	FIM FUNC PARA PEGAR PALAVRA A SER PROCURADA  ==============================

;==================== INICIO FUNC PARA VALIDAR PALAVRA A SER PROCURADA ============================
validaBusca PROC NEAR
	MOV BX, -1
	MOV CX, tam_word
	DEC CX
	MOV indice_word, CX
inicioValida:
	INC BX
;verifica se o char está fora do intervalo das letras
	;se estiver, pede nova palavra
	CMP [word_to_find+BX], 'A'
	JL pedeNovaPalavra
	CMP [word_to_find+BX], 'z'
	JG pedeNovaPalavra
;verifica se o char está no intervalo de caracteres especiais
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
;==================== FIM FUNC PARA VALIDAR PALAVRA A SER PROCURADA ============================

;======================= INICIO FUNC PARA LER PALAVRA DO ARQUIVO ===============================
lePalavraArq PROC NEAR
;le o char do ponteiro apontado pelo arquivo
;compara char com ponto e virgula
	;se for igual, seta flag para avisar que achou ponto e virgula e ve o proximo char
;compara char com espaço
	;se for espaço, acacou a palavra
;compara com CR
	;se for CR, seta a flag para aumentar o numero da linha e acabou a palavra
;compara com LF
	;se for LF, então antes era CR e o vetor precisa ser vazio ('$')
	MOV flag_pontoVirg, 0
	JMP leCharLoop1
pontoEVirgula:
	MOV flag_pontoVirg, 1
leCharLoop1:
	LEA DX, buffer_read
	MOV BX, file_handle  
    MOV AH, LEARQ
    MOV CX, 1
    INT 21H

	CMP [buffer_read], '.'
	JE pontoEVirgula
	CMP [buffer_read], ','
	JE pontoEVirgula
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

fimArq:
	MOV flag_fim_arq, 1
	JMP fimLePalavra
flagIncLinha:
	INC flag_inc_linha
	CMP flag_pontoVirg, 1
	JE fimLePalavra
anteriorEraCR:
	MOV [vet_atual], '$'
fimLePalavra:
	MOV count_letra, -1
	RET
lePalavraArq ENDP
;======================= FIM FUNC PARA LER PALAVRA DO ARQUIVO ==================================

;======================== INICIO FUNC PARA COMPARAR PALAVRAS ===================================
comparaPalavra PROC NEAR
	CALL toUpper
	CALL toUpperVetAtual
contVetAtual:
;calcula o tamanho da palavra atual
	MOV BX, tam_vetAt
	INC BX
	INC tam_vetAt
	CMP [vet_atualUpper+BX], 0
	JNE contVetAtual
;compara o tamanho da palavra lida com o tamanho da palavra a ser procurada no texto
	;se diferentes, já pula para o final
	CMP BX, tam_word
	JNE fimComparaPalavra
;compara a palavra atual com sinal de final de string
	;se igual, significa que é o uma nova linha e não precisa comparar 
	CMP [vet_atual], '$'
	JE fimComparaPalavra
	MOV BX, -1
loopCompara:
;compara char a char entre os vetores da palavra do arquivo em upper case e a palavra a ser buscada também em upper case
	;compara até chegar ao final das palavras ou até achar um char diferente
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
;======================== FIM FUNC PARA COMPARAR PALAVRAS ===================================

;======================== 	INICIO FUNC PARA IMPRIMIR 	 ====================================
imprime PROC NEAR
	INC flag_encontrou
	;seta flag de igual para zero
	MOV flag_igual, 0
	CMP flag_encontrou, 1
	JG pulaFrase

	MOV AH, PRINTSTR
    LEA DX, encontradas
    INT 21H
	
pulaFrase:	
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
;======================== 	FIM FUNC PARA IMPRIMIR 	 ====================================

;======== INICIO FUNC PARA LER A RESPOSTA DO USUARIO SE QUER PROCURAR OUTRA PALAVRA =====
leResposta PROC NEAR
inicioLeResp:
;printa pergunta se usuario quer pesquisar outra palavra
	MOV AH, PRINTSTR
    LEA DX, outra_palavra?
    INT 21H
;pega input do usuario para a resposta
	;essa parte do código foi pega do moodle da disciplica, apenas numeros e variáveis foram alteradas
	PUSH DI
	PUSH SI
    MOV AH, LESTR
    LEA DX, buffer_word
	
    MOV byte ptr buffer_word, 2
    INT 21H
    
    LEA SI, buffer_word+2
    LEA DI, resp
    MOV CL, buffer_word+1
    MOV CH, 0
    MOV AX, DS
    MOV ES, AX
	
    REP MOVSB
	POP SI
	POP DI
;verifica qual foi a resposta do usuario
	CMP resp, 'S'
	JE sim
	CMP resp, 's'
	JE sim
	CMP resp, 'N'
	JE fimleResposta
	CMP resp, 'n'
	JE fimleResposta
;caso o usuario não tenha respondido com 'S/s' ou 'N/n', avisa e pede input novamente
	MOV AH, PRINTCHAR
    MOV DL, [resp]
    INT 21H
	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H
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
	MOV AH, PRINTCHAR
    MOV DL, [resp]
    INT 21H
	MOV AH, PRINTSTR
    LEA DX, eol
    INT 21H
	RET
leResposta ENDP
;======== FIM FUNC PARA LER A RESPOSTA DO USUARIO SE QUER PROCURAR OUTRA PALAVRA =====

;============ INICIO FUNC PARA COLOCAR PALAVRA DO ARQUIVO EM UPPERCASE ===============
toUpperVetAtual PROC NEAR
;coloca para um vetor uma copia da palavra lida do arquivo em upper case
;compara se a letra está fora do intervalo das minúsculas
	;se estiver, só copia a letra para o vetor de upper case
	;senão, subtrai 32 do valor do ascii para pegar a letra maiúscula correspondente e colocar no vetor de upper case
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
	JL copia
	CMP [vet_atual+BX], 'z'
	JG copia
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
;============ FIM FUNC PARA COLOCAR PALAVRA DO ARQUIVO EM UPPERCASE ===============

;========= INICIO FUNC PARA COLOCAR PALAVRA DO A SER BUSCADA EM UPPERCASE =========
toUpper PROC NEAR

	MOV BX, -1
loopUpper2:
	INC BX
;compara se a letra está fora do intervalo das minúsculas
	;se estiver, só copia a letra para o vetor de upper case
	;senão, subtrai 32 do valor do ascii para pegar a letra maiúscula correspondente e colocar no vetor de upper case
	CMP [word_to_find+BX], 'a'
	JL copia2
	CMP [word_to_find+BX], 'z'
	JG copia2
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
;========= FIM FUNC PARA COLOCAR PALAVRA DO A SER BUSCADA EM UPPERCASE =========

;=============  INICIO FUNC PARA TRANSFORMAR INTEIRO EM STRING =================
intToStr PROC NEAR
	MOV flag_passou, 0 
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
	ADD AL, '0'					;transforma o int em char
	MOV [num_linha+BX], AL		;coloca o quociente como o algarismo da centena no vetor
	MOV indice, BX
	MOV flag_passou, 1
dezena:
	CMP flag_passou, 1
	JE pulaCheckDez
	CMP resto, 10
	JL unidade
pulaCheckDez:
	MOV AX, 0
	MOV AL, resto
	MOV BL, 10
	DIV BL
	MOV quociente, AL
	MOV resto, AH
	MOV BX, indice
	INC BX
	ADD AL, '0'					;transforma o int em char
	MOV [num_linha+BX], AL		;coloca o quociente como o algarismo da dezena no vetor
	MOV indice, BX

unidade:
	MOV BX, indice
	INC BX
	MOV AH, resto
	ADD AH, '0'					;transforma o int em char
	MOV [num_linha+BX], AH		;coloca o resto como o algarismo da dezena no vetor
	MOV indice, BX
	MOV[num_linha+BX+1], '$'
	
	RET
intToStr ENDP
;===============  FIM FUNC PARA TRANSFORMAR INTEIRO EM STRING ====================

end
;------------------------------------------------------------------------------------------------------------
; 											END CODE SEGMENT
;------------------------------------------------------------------------------------------------------------