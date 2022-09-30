;aquina de alan turing
;================================================================================
;	Funcionalidades:
;		- Ler um arquivo texto (nome informado pelo usuario sem a extensão .txt);
;		- Criptografar o conteudo do arquivo lido;
;		- Inserir a frase criptograda em um arquivo de saída (MesmoNome.krp);
;	Feito por:
;		- Guilherme Rafael Terres;
;		- Cartao UFRGS: 00338785;
;================================================================================

	.model		small 
	.stack 
	
CR		equ		0DH
LF		equ		0AH

;================================================================================
;								AREA DE DADOS
;================================================================================
	.data	

	; Buffers, handles e variaveis
FileNameSrc		db		256 dup (?) 		; Nome do arquivo a ser lido
FileNameDst		db		256 dup (?)			; Nome do arquivo a ser escrito
FileHandleSrc	dw		0					; Handler do arquivo origem
FileHandleDst	dw		0					; Handler do arquivo destino
FileBuffer		db		10 dup 	(?)			; Buffer de leitura/escrita do arquivo
NaoCriptoMsg 	db 		256 dup (?)			; Guarda a mensagem NAO criptografada informada pelo usuário
charBuffer 		db 		256 dup (?) 		; Guarda o caracter obtido na GetChar
GuardaFileText 	db 		256 dup (?)			; Guarda o texto contido no arquivo para comparação
tamMaxFile 		equ 	65535
tamanhoFile		dw 		0

	; Mensagens de erro
ErroOpenFile		db		"Erro na abertura do arquivo.", CR, LF, 0
ErroCreateFile		db		"Erro na criacao do arquivo.", CR, LF, 0
ErroReadFile		db		"Erro na leitura do arquivo.", CR, LF, 0
ErroWriteFile		db		"Erro na escrita do arquivo.", CR, LF, 0
ErroSizeSentence    db  	"Erro = A frase e grande demais para ser criptografada.", CR, LF, 0
ErroRange			db  	"Erro = Os caracteres estao fora da faixa de representacao.", CR, LF, 0
ErroOpenFWrite 		db 		"Erro = Nao foi possivel abrir o arquivo para escrita.", CR, LF, 0
ErroEmptySentence   db 		"Erro = A frase informada nao contem informacoes."
ErroBigFile 		db 		"Erro = O arquivo e grande demais!", CR, LF, 0

	; Mensagens de interação com o usuário
InformaFileName		db		"Nome do arquivo de origem: ", 0
InformaMsg 			db 		"Entre com uma mensagem para ser criptografada: ", 0


	; Mensagens de atualização
AbreArq				db 		"O arquivo foi aberto para leitura com sucesso!", 0
CriaArq 			db 		"O arquivo foi criado com sucesso!", 0
WriteArq			db 		"O arquivo for aberto para escrita com sucesso!", 0
TamFileEntrada 		db 		"Tamanho do arquivo de entrada - em bytes: ", 0
TamFrase 			db 		"Tamanho da frase - em bytes: ", 0
NomeFileSaida 		db 		"Nome do arquivo de saida gerado: ", 0
Resultado 			db 		"Processamento realizado sem erro.", 0

	; Outras mensagens
MsgCRLF				db	CR, LF, 0 		; Quebra de linha - \n
Separador 			db 		"=============================", 0
	
	; Constantes e variáveis usadas na função gets
MAXSTRING	equ		200
String		db		MAXSTRING dup (?)	

	; Constantes de extensão
extTXT		db		".txt", 0
extKRP 		db 		".krp", 0

;================================================================================
;						AREA DE CODIGO E EXECUCAO (MAIN)
;================================================================================
	.code		
	.startup

	CALL	NomeEntrada				; Chama a funcao NomeEntrada (entrar com o nome do arquivo sem a extensão)
	
	; Define o nome do arquivo de saida
arqSaida:
	LEA 	BX, FileNameSrc 		; Passa o endereço efetivo de FileNameSrc para o registrador BX
	LEA 	DI, FileNameDst			; Passa o endereço efetivo de FileNameSrc para o registrador CX
	CALL 	arqFinal				; Chama a funcao "arqFinal" - nome do arquivo final = nome do arquivo inicial

	; Adiciona ".txt" ao nome arquivo de entrada
addTXT:
	LEA 	BX, FileNameSrc			; Passa o endereço efetivo de FileNameSrc para o registrador BX
	LEA		DI, extTXT				; Passa o endereço efetivo de extTXT para DI 
	CALL 	ext						; Chama a funcao "ext" - colocar a extensao ".txt"

	; Adiciona ".krp" ao nome do arquivo de saida
addKRP:
	LEA 	BX, FileNameDst			; Passa o endereço efetivo de FileNameSrc para o registrador BX
	LEA 	DI, extKRP				; Passa o endereço efetivo de extKRP para DI
	CALL 	ext						; Chama a funcao "ext" - colocar a extensao ".krp"

	; Informar a mensagem a ser criptografada
usuarioInformaMsg: 	
	LEA 	BX, InformaMsg			; Passa o endereço efetivo de InformaMsg para o registrador BX
	CALL 	printf_s				; Chama a funcao de impressão
	LEA		BX, NaoCriptoMsg		; Carrega o endereço de NaoCriptoMsg para BX
	CALL	gets					; Chama a funcao gets
	LEA 	BX, MsgCRLF
	CALL 	printf_s				; Printa uma quebra de linha
	LEA 	BX, NaoCriptoMsg		; NaoCriptoMsg volta para BX

	; Teste para determinar se a mensagem informada pode ser criptografada
		; CRITÉRIOS:	
		; - Caracteres entre " " e "~"
		; - A frase não pode ter mais de 100 caracteres
		;=========
		; OBS: Se alguma dessas condicoes não for atendida, o programa será encerrado com erro
		;=========
validacao:
	LEA 	BX, NaoCriptoMsg		; Passa o endereco efeito de "NaoCriptoMsg" para BX
	CALL 	validaString			; Chama a funcao de validacao da string

	; Se voltar funcao -> string validada

;--------------------------------------------------------------------------------
; --> Tratamento dos arquivos
;--------------------------------------------------------------------------------

	; Abertura do arquivo de entrada
openArqEntrada: 
	LEA		DX, FileNameSrc				
	CALL	fopen					
	MOV		FileHandleSrc, BX		
	JNC		createArq				
	LEA		BX, ErroOpenFile		
	CALL	printf_s
	.exit	1

	; Teste para conferir o tamanho do arquivo
MOV 	CX, 0

tamArq:
	MOV 	BX, FileHandleSrc
	CALL 	GetChar
	JC		erroLeitura
	CMP 	AX, 0
	JE 		createArq
	INC 	CX
	CMP 	CX, tamMaxFile
	JA 		erroTamFile
	JMP 	tamArq

erroLeitura:
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, ErroReadFile
	CALL 	printf_s
	.exit 	1

erroTamFile:
	LEA 	BX, ErroBigFile
	CALL 	printf_s
	.exit 	1	

createArq:
		; Mensagem informa que o arquivo foi aberto com sucesso
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA 	BX, AbreArq
	CALL 	printf_s
		; Cria arquivo ".krp"
	LEA 	DX, FileNameDst
	CALL 	fcreate
	MOV		FileHandleDst, BX
	JNC		openFWrite
	MOV		BX, FileHandleDst
	CALL	fclose
	LEA		BX, ErroCreateFile
	CALL	printf_s
	.exit	1

openFWrite:
		; Mensagem informa que o arquivo foi criado com sucesso
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA 	BX, CriaArq
	CALL 	printf_s
		; Abre arquivo ".krp" para escrita		
	LEA 	DX, FileNameDst
	CALL 	fwrite
	MOV		FileHandleDst, BX
	JNC		upper
	MOV		BX, FileHandleDst
	CALL	fclose
	LEA		BX, ErroOpenFWrite
	CALL	printf_s
	.exit	1

	; Transforma para maiusculo
upper:
		; Mensagem informa que o arquivo foi aberto para leitura com sucesso
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA		BX, WriteArq
	CALL 	printf_s

	LEA 	BX, NaoCriptoMsg
	CALL 	toupper					; Chama a funcao "toupper"

; -------------------------------------------------------------------------------

;----- LENDO ARQUIVO -----
 
;	LEA 	SI, NaoCriptoMsg			;  BX <- EA (NaoCriptoMsg)
;loop_ler_arq:	
;	CMP 	byte ptr [SI], 0
;	JE 		fim_frase
;	CMP 	byte ptr [SI], 32 			; 32 = Space
;	JE 		nao_faz_nada
;
;	rewind:	
;		LEA		DX, FileNameSrc				
;		CALL	fopen					
;		MOV		FileHandleSrc, BX		
;		JNC		verifica_arquivo				
;		LEA		BX, ErroOpenFile		
;		CALL	printf_s
;		.exit	1
;		
;		
;	verifica_arquivo:	
; 		MOV 	BX, FileHandleSrc
;		CALL 	GetChar
;		JC 		informa_erro
;		CMP 	AX, 0
;		JE 		nao_faz_nada
;		MOV 	charBuffer, DL
;		CMP 	[SI], DL
;		JE 		addArq
;		JMP 	verifica_arquivo
;
;	addArq:
;
;		.exit
;
;	nao_faz_nada:	
;		INC		SI
;		JMP 	loop_ler_arq
;
;informa_erro:
;	LEA 	BX, ErroReadFile
;	CALL 	printf_s
;	.exit 	1
;
;fim_frase: 

LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, Separador
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, TamFileEntrada
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, TamFrase
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, TamFileEntrada
CALL 	printf_s
LEA 	BX, FileNameDst
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, Resultado
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s
LEA 	BX, Separador
CALL 	printf_s

.exit 	0

;================================================================================
;									FUNCOES
;================================================================================	

setChar		proc	near
	MOV		AH, 40h
	MOV		CX, 1
	MOV		FileBuffer, DL
	LEA		DX, FileBuffer
	INT		21h
	RET
setChar		endp	

	; "Captura" o caracter para leitura ou escrita no arquivo
GetChar		proc	near
	MOV		AH, 3FH
	MOV		CX, 1
	LEA		DX, FileBuffer
	INT		21H
	MOV		DL, FileBuffer
	RET
GetChar		endp

	; --------------------------------------------------
	; Imprime InformaFileName e recebe o nome do arquivo
	; * BX <- InformaNameFile, FileNameSrc, MsgCRLF
	; --------------------------------------------------

NomeEntrada		proc	near
		; Imprime InformaFileName
	LEA		BX, InformaFileName		; Carrega o endereço de InformaFileName para BX
	CALL	printf_s				; Chama a função printf_s	
		
		; Recebe o nome do arquivo
	LEA		BX, FileNameSrc			; Carrega o endereço de FileNameSrc para BX
	CALL	gets					; Chama a função gets
	
		; Imprime quebra de linha
	LEA		BX, MsgCRLF				; Carrega o endereço de MsgCRLF para BX
	CALL	printf_s				; Chama a função printf_s
	
	RET								; Fim da subrotina
NomeEntrada		endp

	; Função de impressão na tela (printf)
printf_s	proc	near
	MOV		DL, [BX]				; Passa o conteúdo de BX para DL, byte por byte
	CMP		DL, 0					; Enquanto o byte for != de \0, continua...
	JE		Ret_printf_s			; Senão, retorna da subrotina

	PUSH 	BX						; Coloca o endereço contido em BX na pilha
	MOV		AH, 2					
	INT		21H						; Define o tipo de interrupçao
	POP		BX						; Tira o elemento do topo da pilha e põe em BX

	INC		BX						; Incrementa para pegar o próximo byte (caracter)
	JMP		printf_s				; Volta para o início da função
		
Ret_printf_s:
	RET								; Fim da subrotina
printf_s	endp

	; Função de entrada (scanf)
gets		proc	near
	PUSH	BX								; Coloca o endereço armazenado em BX na pilha

	MOV		AH, 0AH							; Lê uma linha do teclado
	LEA		DX, String
	MOV		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	INT		21H

	LEA		SI, String+2					; Copia do buffer de teclado para o FileNameSrc
	POP		DI
	MOV		CL, String+1
	MOV		CH, 0
	MOV		AX, DS							; Ajusta ES=DS para poder usar o MOVSB
	MOV		ES, AX
	REP 	MOVSB

	MOV		byte ptr ES:[DI], 0				; Coloca marca de fim de string
	RET
gets		endp

	; Função de abertura do arquivo (fopen)
fopen		proc	near
	MOV		AL, 0
	MOV		AH, 3DH							; Define o AH = 3DH (condição de abertura)
	INT		21H
	MOV		BX, AX
	RET
fopen		endp

	; Função de abertura do arquivo para escrita (fwrite)
fwrite 		proc 	near
	MOV		AL, 1
	MOV		AH, 3DH							; Define o AH = 3DH (condição de abertura)
	INT		21H
	MOV		BX, AX
	RET
fwrite 		endp

	; Função para criação de arquivo (fcreate)
fcreate 	proc 	near
	MOV		CX, 0
	MOV		AH, 3CH
	INT		21H
	MOV		BX, AX	
	RET
fcreate 	endp

	; Função para fechar um arquivo (fclose)
fclose		proc	near
	mov		ah,3eh
	int		21h
	ret
fclose		endp

	; --------------------------------------------------
	; Função para colocar a extensão no arquivo
	; * BX <- FileNameSrc
	; * DI <- extTXT, extKRP
	; --------------------------------------------------
	
ext		proc 	near
	MOV 	AL, 0
	loop_ext:
		CMP 	[BX], AL					; Compara com a posição do ponteiro com zero
		JE		coloca_ext					; Se igual a zero: chegou no fim da string - pula para colocar a extensão
		INC 	BX							; Caso não, incrementa o ponteiro que percorre a string
		JMP 	loop_ext					; Volta para o início do loop

	coloca_ext:
		CMP		[DI], AL					; Compara o conteúdo do endereço apontado por DI com 0
		JE		retorna_ext					; Se for igual significa que todos os caracteres foram inseridos
		MOV		CX, [DI]					; Move o conteúdo da posição de memória guardada DI (extensão) para o registrador CX
		MOV		[BX], CX					; Move o conteúdo de CX (extensão) para o nome do arquivo
		ADD		BX, 1						; Incrementa BX
		ADD		DI, 1						; Incrementa DI
		
		JMP 	coloca_ext	

	retorna_ext:
		MOV		AX, 0
		MOV		BX, 0
		MOV 	CX, 0						; Zera todos os registradores utilizados antes de voltar da função
		MOV 	DI, 0						

		RET 								; Retorna da função
ext 	endp

	; -----------------------------------------------------------------------
	; Função para copiar o nome do arquivo de entrada para o arquivo de saída
	; * BX <- FileNameSrc
	; * DI <- FileNameDst
	; -----------------------------------------------------------------------
	
arqFinal	proc	near
	MOV 	AL, 0
	loop_arqFinal:
		CMP 	[BX], AL					; Compara o conteúdo do endereço apontado por BX com 0
		JE 		retorna_loop_arqFinal 		; Se igual 0, chegou no final da string - pula para o fim
		MOV 	CX, [BX]					; Move conteúdo do endereço guardado por BX para CX - FileNameSrc
		MOV 	[DI], CX					; Move o conteúdo de CX para o endereço guardado por DI - FileNameDst
		INC 	BX
		INC		DI
		JMP 	loop_arqFinal

	retorna_loop_arqFinal:
		MOV 	AX, 0
		MOV 	BX, 0						; Zera todos os registradores utilizados antes de voltar da função
		MOV 	CX, 0
		MOV 	DI, 0

		RET
arqFinal 	endp

	; Analisa a mensagem informada pelo usuário e verifica se ele pode ser criptografada
validaString	proc 	near

		; Analisa o tamanho da frase em caracteres
	MOV 	AL, 0
		; Analisa o tamanho da string
	loop_tam_string:
		CMP 	CX, 102						; Compara o contador com 101
		JE 		ErroTamanho					; Se for igual, informa que o tamanho da frase não é permitido 
		CMP		[BX], AL					; Caso não, não continua a analise - testa se chegou ao fim da string
		JE 		testeFraseVazia				; Pula para a próxima análise
		INC 	BX							; Incrementa BX - Navegar pela string
		INC     CX							; Incrementa o contador CX
		JMP 	loop_tam_string				; Volta para o início do loop

	testeFraseVazia:
		CMP 	CX, 0
		JE 		ErroVazio

		; Dá um "reset" nas configurações para continuar com a execução da função
	resetConfig:	
		LEA  	BX, NaoCriptoMsg
		MOV 	AX, 0
		MOV 	CX, 0

		; Analisa intervalo do caracter
	loop_intervalo:
		CMP 	byte ptr [BX], ' '
		JL		ErroIntervalo
		CMP 	byte ptr [BX], '~'
		JG 		ErroIntervalo
		INC 	BX
		CMP 	[BX], CL 
		JE 		retorna_validaString
		JMP     loop_intervalo

		; Informa erros
	ErroIntervalo:
		LEA 	BX, ErroRange				; Informa o erro do intervalo de representação
		CALL 	imprime_encerra_erro

	ErroTamanho:
		LEA		BX, ErroSizeSentence 		; Informa o erro do tamanho do arquivo
		CALL 	imprime_encerra_erro

	ErroVazio:
		LEA  	BX, ErroEmptySentence		; Informa que a frase "informada esta vazia"
		CALL 	imprime_encerra_erro

	retorna_validaString:
		MOV		AX, 0						
		MOV 	BX, 0						; Zera todos os registradores utilizados
		MOV 	CX, 0

		RET 
validaString 	endp

	; Imprime uma mensagem em caso de erro, fecha o arquivo e encerra o programa
imprime_encerra_erro 	proc	near
		CALL 	printf_s					; Imprime a mensagem de erro
		LEA		BX, MsgCRLF					; Move o endereço efeitivo de MsgCRLF (quebra de linha)
		CALL 	printf_s					; Imprime a quebra
		CALL 	fclose						; Fecha o arquivo

retorna_imprime_encerra_erro:
		.exit 	1	 						; Retorna o valor 1 e fecha encerra a execução
		
imprime_encerra_erro 	endp

toupper 	proc 	near
	loop_toupper:
		CMP 	byte ptr [BX], 0					; Compara o ponteiro da string com zero - verifica se a string chegou ao fim
		JE 		retorna_toupper
			; Teste se o caracter ja eh maiusculo
		CMP 	byte ptr [BX], 'A'					; Se for menor que 'A', incrementa o ponteiro
		JB 		inc_ponteiro 						; Incrementa o ponteiro	
		CMP 	byte ptr [BX], 'Z'					; Se for maior que 'Z', teste pra ver se o caracter eh maisculo 
		JA 		testaLow					
		JMP 	inc_ponteiro						; Senao, apenas incrementa o ponteiro
			
			; Teste se o caracter está entre 'a' e 'z'
		testaLow:
			CMP		byte ptr [BX], 'a'			; Se for menor que 'a'
			JB		inc_ponteiro
			CMP		byte ptr [BX], 'z'						
			JA		inc_ponteiro
			SUB		byte ptr [BX], 20h	
		inc_ponteiro:	
			INC 	BX
		JMP 	loop_toupper

	retorna_toupper:
		MOV 	BX, 0
		RET
toupper 	endp

	end 									; FIM