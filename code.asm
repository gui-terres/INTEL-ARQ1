;================================================================================
;	Funcionalidades:
;		- Ler um arquivo texto (nome informado pelo usuario sem a extensao .txt);
;		- Criptografar o conteudo do arquivo lido;
;		- Inserir a frase criptograda em um arquivo de saida (MesmoNome.krp);
;	Feito por:
;		- Guilherme Rafael Terres;
;		- Cartao UFRGS: 00338785;
;================================================================================

	.model		small 
	.stack 
	
CR		equ		0DH 						; Carriage return
LF		equ		0AH							; Line feed

;================================================================================
;								AREA DE DADOS
;================================================================================

	.data	

	; Buffers, handles e variaveis
FileNameSrc		db		256 dup (?) 		; Nome do arquivo a ser lido
FileNameDst		db		256 dup (?)			; Nome do arquivo a ser escrito
FileHandleSrc	dw		0					; Handler do arquivo origem
FileHandleDst	dw		0					; Handler do arquivo destino
FileBuffer		db		10 	dup (?)			; Buffer de leitura/escrita do arquivo
NaoCriptoMsg 	db 		256 dup (?)			; Guarda a mensagem NAO criptografada informada pelo usuario
GuardaFileText 	db 		256 dup (?)			; Guarda o texto contido no arquivo para comparacao
charBuffer 		db 		256 dup (?) 		; Guarda o caracter obtido na GetChar
tamMaxFile 		equ 	65535				; Tamanho maximo do arquivo = 65535 bytes
tamanhoFile		dw 		0					; Armazena o tamanho do arquivo em bytes
tamanhoString 	dw		0					; Armazena o tamanho da string em bytes 
Contador		dw      0 					; Armazena a posicao da letra no arquivo
GuardaPosArq	dw		200 dup (?) 		; Vetor para armazenar as posicoes ja acessadas do arquivo
flag			db		0					; Flag para verificar se o caractere existe no arquivo
tamanho			dw		0					; Armazena o tamanho do array
pt1 			dw		6553
pt2				dw		6

	; Mensagens de erro
ErroOpenFile		db		"Erro na abertura do arquivo.", CR, LF, 0
ErroCreateFile		db		"Erro na criacao do arquivo.", CR, LF, 0
ErroReadFile		db		"Erro na leitura do arquivo.", CR, LF, 0
ErroWriteFile		db		"Erro na escrita do arquivo.", CR, LF, 0
ErroSizeSentence    db  	"Erro: A frase e grande demais para ser criptografada.", CR, LF, 0
ErroRange			db  	"Erro: Algum caractere esta fora da faixa de representacao.", CR, LF, 0
ErroOpenFWrite 		db 		"Erro: Nao foi possivel abrir o arquivo para escrita.", CR, LF, 0
ErroEmptySentence   db 		"Erro: A frase informada nao contem informacoes.", 0
ErroBigFile 		db 		"Erro: O arquivo e grande demais.", CR, LF, 0
ErroNotFind			db      "Erro: O caractere nao pode ser encontrado no arquivo", CR, LF, 0

	; Mensagens de interacao com o usuario
InformaFileName		db		"Nome do arquivo de origem: ", 0
InformaMsg 			db 		"Entre com uma mensagem para ser criptografada: ", 0

	; Mensagens de atualizacao
AbreArq				db 		"O arquivo foi aberto para leitura com sucesso!", 0
CriaArq 			db 		"O arquivo foi criado com sucesso!", 0
WriteArq			db 		"O arquivo foi aberto para escrita com sucesso!", 0

	; Mensagens finais
TamFileEntrada 		db 		"Tamanho do arquivo de entrada - em bytes: ", 0
TamFrase 			db 		"Tamanho da frase - em bytes: ", 0
NomeFileSaida 		db 		"Nome do arquivo de saida gerado: ", 0
Resultado 			db 		"Processamento realizado sem erro.", 0

	; Outras mensagens 
MsgCRLF				db		CR, LF, 0 		; Quebra de linha - \n
Separador 			db 		"=============================", 0
	
	; Constantes e variaveis usadas na funcao gets
MAXSTRING	equ		200
String		db		MAXSTRING dup (?)	

	; Constantes de extensao
extTXT		db		".txt", 0				; Constante .txt
extKRP 		db 		".krp", 0				; Constante .krp

;================================================================================
;						AREA DE CODIGO E EXECUCAO (MAIN)
;================================================================================

	.code		
	.startup

	CALL	NomeEntrada				; Chama a funcao NomeEntrada (entrar com o nome do arquivo sem a extensao)
	
	; Define o nome do arquivo de saida
arqSaida:
	LEA 	BX, FileNameSrc 		; Passa o endereco efetivo de FileNameSrc para o registrador BX
	LEA 	DI, FileNameDst			; Passa o endereco efetivo de FileNameSrc para o registrador CX
	CALL 	arqFinal				; Chama a funcao "arqFinal" - nome do arquivo final = nome do arquivo inicial

	; Adiciona ".txt" ao nome arquivo de entrada
addTXT:
	LEA 	BX, FileNameSrc			; Passa o endereco efetivo de FileNameSrc para o registrador BX
	LEA		DI, extTXT				; Passa o endereco efetivo de extTXT para DI 
	CALL 	ext						; Chama a funcao "ext" - colocar a extensao ".txt"

	; Adiciona ".krp" ao nome do arquivo de saida
addKRP:
	LEA 	BX, FileNameDst			; Passa o endereco efetivo de FileNameSrc para o registrador BX
	LEA 	DI, extKRP				; Passa o endereco efetivo de extKRP para DI
	CALL 	ext						; Chama a funcao "ext" - colocar a extensao ".krp"

	; Informar a mensagem a ser criptografada
usuarioInformaMsg: 	
	LEA 	BX, InformaMsg			; Passa o endereco efetivo de InformaMsg para o registrador BX
	CALL 	printf_s				; Chama a funcao de impressao
	LEA		BX, NaoCriptoMsg		; Carrega o endereco de NaoCriptoMsg para BX
	CALL	gets					; Chama a funcao gets
	LEA 	BX, MsgCRLF
	CALL 	printf_s				; Printa uma quebra de linha
	LEA 	BX, NaoCriptoMsg		; NaoCriptoMsg volta para BX

	; Teste para determinar se a mensagem informada pode ser criptografada
	; CRITERIOS:	
	; - Caracteres entre " " e "~"
	; - A frase nao pode ter mais de 100 caracteres
	; - OBS: Se alguma dessas condicoes nao for atendida, o programa sera encerrado com erro

validacao:
	LEA 	BX, NaoCriptoMsg		; Passa o endereco efeito de "NaoCriptoMsg" para BX
	CALL 	validaString			; Chama a funcao de validacao da string

	; Calcula o tamanho da string
tamString:
	LEA		BX, NaoCriptoMsg		
	CALL	calcTamString

;--------------------------------------------------------------------------------
; --> Tratamento dos arquivos
;--------------------------------------------------------------------------------

	; Abertura do arquivo de entrada
openArqEntrada: 
	LEA		DX, FileNameSrc			; O handle do arquivo de entrada e passado para DX		
	CALL	fopen					; Funcao de abertura do arquivo e passada
	MOV		FileHandleSrc, BX		; BX e movido para o handle do arquivo de entrada
	JNC		preTamArq					; Nao Carry -> o arquivo foi aberto 
	LEA     BX, MsgCRLF
	CALL	printf_s				; Imprime uma quebra de linha
	LEA		BX, ErroOpenFile		; Carry -> Mensagem de erro na abertura
	CALL	printf_s				; Imprime a mensagem na tela 
	.exit	1

	; Teste para conferir o tamanho do arquivo
MOV 	CX, 0
	; Pula o primeiro caracter para evitar overflow em caso de o tamanho ser maior que 65535
preTamArq:
	MOV 	BX, FileHandleSrc		; O handle do arquivo de entrada e passado para DX	
	CALL 	GetChar					; A funcao GetChar e chamada
	JC		erroLeitura				; Se der carry, houve um erro na leitura do arquivo
	CMP 	AX, 0					; Se ao ler mais nada, cria o arquivo
	JE 		createArq				; Chama a funcao para criar o arquivo de destino

tamArq:
	MOV 	BX, FileHandleSrc		; O handle do arquivo de entrada e passado para DX	
	CALL 	GetChar					; A funcao GetChar e chamada
	JC		erroLeitura				; Se der carry, houve um erro na leitura do arquivo
	CMP 	AX, 0					; Se ao ler mais nada, cria o arquivo
	JE 		createArq				; Chama a funcao para criar o arquivo de destino
	INC 	tamanhoFile				; Incrementa o contador do tamanho do arquivo
	MOV		CX, tamanhoFile
	CMP 	CX, 0					; Compara o contador com o 65535 ;;;;;;;;
	JE 		erroTamFile				; Se for maior: o tamanho do arquivo e maior do que o permitido
	JMP 	tamArq					; Volta para o loop

	; Mensagem de erro na leitura do arquivo
erroLeitura:
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, ErroReadFile
	CALL 	printf_s
	.exit 	1
	
	; Mensagem de erro no tamanho do arquivo
erroTamFile:
	LEA 	BX, MsgCRLF
	CALL 	printf_s	
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
	LEA 	DX, FileNameDst			; Move o handle do arquivo de saida para DX
	CALL 	fcreate					; Chama a funcao de criacao do arquivo
	MOV		FileHandleDst, BX		; FileHandleDst <- BX
	JNC		openFWrite				; Nao Carry -> Abrir o arquivo para escrita
	MOV		BX, FileHandleDst		; Carry -> Fecha o arquivo
	CALL	fclose
	LEA		BX, ErroCreateFile		; Informa o erro
	CALL	printf_s
	.exit	1

openFWrite:
		; Mensagem informa que o arquivo foi criado com sucesso
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA 	BX, CriaArq
	CALL 	printf_s
		; Abre arquivo ".krp" para escrita		
	LEA 	DX, FileNameDst			; Move o handle do arquivo de saida para DX
	CALL 	fwrite					; Abre o arquivo de saida para escrita
	MOV		FileHandleDst, BX		; FileHandleDst <- BX
	JNC		upper					; Nao carry -> pula para upper
	MOV		BX, FileHandleDst
	CALL	fclose				 	; Fecha o arquivo
	LEA		BX, ErroOpenFWrite		; Imprime a mensagem de erro na abertura do arquivo para escrita
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

;--------------------------------------------------------------------------------
; --> Leitura e escrita no arquivo
;--------------------------------------------------------------------------------
 
LEA 	SI, NaoCriptoMsg						; BX <- EA (NaoCriptoMsg)
JMP		loop_ler_arq

	; Loop de leitura e escrita no arquivo
pre_loop_ler_arq:
	CMP		flag, 0								; Compara a flag com zero
	JNE		loop_ler_arq						; Se nao igual, pula para loop_ler_arq
	LEA		BX, MsgCRLF							; Imprime quebra de linha
	CALL	printf_s
	LEA		BX, MsgCRLF							; Imprime quebra de linha
	CALL	printf_s
	LEA		BX, ErroNotFind						; Informa o erro
	CALL	printf_s
	.exit 	1

loop_ler_arq:	
	CMP 	byte ptr [SI], 0					; Verifica o fim da string
	JE		Final								; Se [SI] = 0, pula para o fim
	CMP 	byte ptr [SI], 32 					; 32 = Space
	JE 		nao_faz_nada						; Se [SI] = (space), apenas incrementa o SI
	JMP 	rewind

	Final:
		MOV		BX, FileHandleDst				; Move o FileHandleDst para BX
		MOV		AH, 40H							; AH <- 40H
		MOV 	CX, tamanho						; CX <- tamanho
		LEA 	DX, GuardaPosArq				; DX <- GuardaPosArq (array de posicoes)
		INT 	21H 							; Chama a interrupcao
    	JNC  	acabou							; Se nao der carry, pula para o fim
    	LEA 	BX, ErroWriteFile				; Se der carry, imprime o erro de escrita no arquivo
    	CALL 	printf_s
    	.exit 	1
		
		acabou:
			MOV		BX, FileHandleDst			; Move o handle do arquivo de destino para BX
			MOV		DL, 0						; DL <- 0
			CALL	setChar						; Imprime o zero no fim do arquivo de destino
			INC 	tamanhoFile					; Incrementa o tamanho do arquivo para contabilizar o byte desprezado
			MOV		AX, tamanhoFile
			CMP		AX, 0
			JE		bytes
			CALL	resumoFinal					; Imprime o resumo das operacoes 
			JMP		close
			bytes:
				CALL 	resumoFinal65536
			close:
				MOV 	BX, FileHandleSrc			; Fecha o arquivo de entrada
				CALL	fclose
				MOV		BX, FileHandleDst			; Fecha o arquivo de saida
				CALL	fclose
			.exit 	0

	nao_faz_nada:								
		INC		SI								; Incrementa a posicao na string
		JMP 	loop_ler_arq					; Volta para o loop

		; Abre o arquivo de entrada para leitura (tambem rebobina o arquivo)
	rewind:	
		LEA		DX, FileNameSrc					; Move FileNameSrc para DX
		CALL	fopen							; Abre o arquivo
		MOV		FileHandleSrc, BX				; FileHandleSrc <- BX
		JNC		first_char       				; Nao carry -> compara a letra com o arquivo
		LEA		BX, ErroOpenFile				; Imprime a mensagem de erro
		CALL	printf_s
		.exit	1
	
		; le o primeiro caracter apenas
	first_char:	
		INC 	Contador
		MOV 	BX, FileHandleSrc				; BX <- FileHandleSrc
		CALL 	GetChar							; "Pega" um caracter 
		JC 		informa_erro					; Carry <- Informa o erro
		CMP 	AX, 0							; Se chegar no fim do arquivo, pula
		JE 		fim_file

	MOV		flag, 0								; Inicializa a flag com zero

		; Verifica o arquivo
	verifica_arquivo:	
 		MOV 	BX, FileHandleSrc				; BX <- FileHandleSrc
		CALL 	GetChar							; "Pega" um caracter 
		JC 		informa_erro					; Carry <- Informa o erro
		CMP 	AX, 0							; Se chegar no fim do arquivo, pula
		JE 		fim_file
		;---------Toupper---------;				; Converte o caracter tirado do arquivo em maiusculo
		MOV		charBuffer, DL 					
		LEA 	BX, charBuffer
		CALL  	toupper
		MOV  	DL, charBuffer
		;-------------------------;
		CMP 	[SI], DL						; Compara o caracter em [SI] com DL
		JE 		Array							; Se igual, verifica se a posicao ja foi adicionada
		INC   	Contador						; Incrementa a posicao 
		JMP 	verifica_arquivo				; Volta para o loop

	Array:
		MOV		DI, Contador					; DI <- Contador
		LEA		BX, GuardaPosArq				; BX <- GuardaPosArq (array de posicoes)

		; Comparar
		compArrayCont:
			CMP		word ptr [BX], 0			; Se chegar no fim do array, pula para addArq
			JE		addArq
			CMP		[BX], DI					; Se a posicao for igual ao conteudo do arry, volta para o loop
			JE 		volta
			ADD		BX, 2						; BX += 2
			JMP		compArrayCont				; Volta para o loop

			volta:								; Volta para verifica_arquivo
				INC		Contador
				JMP		verifica_arquivo

	addArq:
		MOV		AX, Contador					; Move o contador para AX
		MOV		[BX], AX						; Move AX para o array
		MOV		Contador, 0						; Zera a posicao no arquivo
		ADD		tamanho, 2						; tamanho += 2
		INC     flag							; Incrementa a flag
		INC 	SI								; Incrementa posicao da frase
		MOV		BX, FileHandleSrc
		CALL 	fclose							; Fecha o arquivo
		JMP 	pre_loop_ler_arq				; Volta para o loop	
		
		; Informa o erro na leitura do arquivo
	informa_erro:
		LEA 	BX, ErroReadFile
		CALL 	printf_s
		.exit 	1

	fim_file:
		INC 	SI								; Incrementa a posicao na string
		MOV		BX, FileHandleSrc				
		CALL	fclose							; Fecha o arquivo
		JMP 	pre_loop_ler_arq				; Volta para o loop

;================================================================================
;									FUNCOES
;================================================================================	

	; Poe um caracter no arquivo
setChar		proc	near
	MOV		AH, 40h
	MOV		CX, 2
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
	LEA		BX, InformaFileName		; Carrega o endereco de InformaFileName para BX
	CALL	printf_s				; Chama a funcao printf_s	
		
		; Recebe o nome do arquivo
	LEA		BX, FileNameSrc			; Carrega o endereco de FileNameSrc para BX
	CALL	gets					; Chama a funcao gets
	
		; Imprime quebra de linha
	LEA		BX, MsgCRLF				; Carrega o endereco de MsgCRLF para BX
	CALL	printf_s				; Chama a funcao printf_s
	
	RET								; Fim da subrotina
NomeEntrada		endp

	; Funcao de impressao na tela (printf)
printf_s	proc	near
	MOV		DL, [BX]				; Passa o conteudo de BX para DL, byte por byte
	CMP		DL, 0					; Enquanto o byte for != de \0, continua...
	JE		Ret_printf_s			; Senao, retorna da subrotina

	PUSH 	BX						; Coloca o endereco contido em BX na pilha
	MOV		AH, 2					
	INT		21H						; Define o tipo de interrupcao
	POP		BX						; Tira o elemento do topo da pilha e poe em BX

	INC		BX						; Incrementa para pegar o proximo byte (caracter)
	JMP		printf_s				; Volta para o inicio da funcao
		
Ret_printf_s:
	RET								; Fim da subrotina
printf_s	endp

	; Funcao de entrada (scanf)
gets		proc	near
	PUSH	BX								

	MOV		AH, 0AH							
	LEA		DX, String
	MOV		byte ptr String, MAXSTRING-4	
	INT		21H

	LEA		SI, String+2					
	POP		DI
	MOV		CL, String+1
	MOV		CH, 0
	MOV		AX, DS							
	MOV		ES, AX
	REP 	MOVSB

	MOV		byte ptr ES:[DI], 0				
	RET
gets		endp

	; Funcao de abertura do arquivo (fopen)
fopen		proc	near
	MOV		AL, 0
	MOV		AH, 3DH							; Define o AH = 3DH (condicao de abertura)
	INT		21H
	MOV		BX, AX
	RET
fopen		endp

	; Funcao de abertura do arquivo para escrita (fwrite)
fwrite 		proc 	near
	MOV		AL, 1
	MOV		AH, 3DH							; Define o AH = 3DH (condicao de abertura)
	INT		21H
	MOV		BX, AX
	RET
fwrite 		endp

	; Funcao para criacao de arquivo (fcreate)
fcreate 	proc 	near
	MOV		CX, 0
	MOV		AH, 3CH
	INT		21H
	MOV		BX, AX	
	RET
fcreate 	endp

	; Funcao para fechar um arquivo (fclose)
fclose		proc	near
	mov		ah,3eh
	int		21h
	ret
fclose		endp

	; --------------------------------------------------
	; Funcao para colocar a extensao no arquivo
	; * BX <- FileNameSrc
	; * DI <- extTXT, extKRP
	; --------------------------------------------------
	
ext		proc 	near
	MOV 	AL, 0
	loop_ext:
		CMP 	[BX], AL					; Compara com a posicao do ponteiro com zero
		JE		coloca_ext					; Se igual a zero: chegou no fim da string - pula para colocar a extensao
		INC 	BX							; Caso nao, incrementa o ponteiro que percorre a string
		JMP 	loop_ext					; Volta para o inicio do loop

	coloca_ext:
		CMP		[DI], AL					; Compara o conteudo do endereco apontado por DI com 0
		JE		retorna_ext					; Se for igual significa que todos os caracteres foram inseridos
		MOV		CX, [DI]					; Move o conteudo da posicao de memoria guardada DI (extensao) para o registrador CX
		MOV		[BX], CX					; Move o conteudo de CX (extensao) para o nome do arquivo
		ADD		BX, 1						; Incrementa BX
		ADD		DI, 1						; Incrementa DI
		
		JMP 	coloca_ext	

	retorna_ext:
		MOV		AX, 0
		MOV		BX, 0
		MOV 	CX, 0						; Zera todos os registradores utilizados antes de voltar da funcao
		MOV 	DI, 0						

		RET 								; Retorna da funcao
ext 	endp

	; -----------------------------------------------------------------------
	; Funcao para copiar o nome do arquivo de entrada para o arquivo de saida
	; * BX <- FileNameSrc
	; * DI <- FileNameDst
	; -----------------------------------------------------------------------
	
arqFinal	proc	near
	MOV 	AL, 0
	loop_arqFinal:
		CMP 	[BX], AL					; Compara o conteudo do endereco apontado por BX com 0
		JE 		retorna_loop_arqFinal 		; Se igual 0, chegou no final da string - pula para o fim
		MOV 	CX, [BX]					; Move conteudo do endereco guardado por BX para CX - FileNameSrc
		MOV 	[DI], CX					; Move o conteudo de CX para o endereco guardado por DI - FileNameDst
		INC 	BX
		INC		DI
		JMP 	loop_arqFinal

	retorna_loop_arqFinal:
		MOV 	AX, 0
		MOV 	BX, 0						; Zera todos os registradores utilizados antes de voltar da funcao
		MOV 	CX, 0
		MOV 	DI, 0

		RET
arqFinal 	endp

	; Analisa a mensagem informada pelo usuario e verifica se ele pode ser criptografada
validaString	proc 	near
		; Analisa o tamanho da frase em caracteres
		; Analisa o tamanho da string
	
	MOV		CX, 0							; Zera CX

	loop_tam_string:
		CMP 	CX, 101						; Compara o contador com 101
		JE 		ErroTamanho					; Se for igual, informa que o tamanho da frase nao e permitido 
		CMP		byte ptr [BX], 0			; Caso nao, nao continua a analise - testa se chegou ao fim da string
		JE 		testeFraseVazia				; Pula para a proxima analise
		INC 	BX							; Incrementa BX - Navegar pela string
		INC     CX							; Incrementa o contador CX
		JMP 	loop_tam_string				; Volta para o inicio do loop

	testeFraseVazia:						; Se nada for digitado, informa o erro
		CMP 	CX, 0
		JE 		ErroVazio

		; Da um "reset" nas configuracoes para continuar com a execucao da funcao
	resetConfig:	
		LEA  	BX, NaoCriptoMsg
		MOV 	AX, 0
		MOV 	CX, 0

		; Analisa intervalo do caracter
	loop_intervalo:
		CMP 	byte ptr [BX], ' '			; Se [BX] < (space), informa o erro
		JL		ErroIntervalo
		CMP 	byte ptr [BX], '~'			; Se [BX] > ~, informa o erro
		JG 		ErroIntervalo
		INC 	BX							; Incrementa BX - Navegar pela string
		CMP 	byte ptr [BX], 0			; Se [BX] = 0 -> string terminou 	
		JE 		retorna_validaString		; Pula para o retorno da funcao
		JMP     loop_intervalo				; Volta para o inicio do loop

		; Informa erros
	ErroIntervalo:
		LEA 	BX, ErroRange				; Informa o erro do intervalo de representacao
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

	; Calcula o tamanho da string
calcTamString 	proc	near
	loop_calcTamString:
		CMP		byte ptr [BX], 0 			; Se [BX] = 0, a string chegou ao fim
		JE		retorna_calcTamString		; Pula para o retorno da funcao 
		INC		BX							; Incrementa BX (ponteiro da string) -> Navegar pela string
		INC		tamanhoString				; Incrementa o contador para calcular o tamanho da string
		JMP		loop_calcTamString			; Retorna para o loop

		; Retorna da funcao
	retorna_calcTamString:
		RET
calcTamString	endp

	; Imprime uma mensagem em caso de erro, fecha o arquivo e encerra o programa
imprime_encerra_erro 	proc	near
		CALL 	printf_s					; Imprime a mensagem de erro
		LEA		BX, MsgCRLF					; Move o endereco efetivo de MsgCRLF (quebra de linha)
		CALL 	printf_s					; Imprime a quebra
		CALL 	fclose						; Fecha o arquivo

retorna_imprime_encerra_erro:
		.exit 	1	 						; Retorna o valor 1 e fecha encerra a execucao
imprime_encerra_erro 	endp

	; Transforma o caracter em maiusculo
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
			
			; Teste se o caracter esta entre 'a' e 'z'
		testaLow:
			CMP		byte ptr [BX], 'a'			; Se for menor que 'a', pula para incrementar o BX e voltar para o loop
			JB		inc_ponteiro			
			CMP		byte ptr [BX], 'z'			; Se for maior que 'z', pula para incrementar o BX e voltar para o loop				
			JA		inc_ponteiro
			SUB		byte ptr [BX], 20H			; Subtrai 20H para transformar o caracter em maiusculo
		inc_ponteiro:	
			INC 	BX							; Incrementa BX -> Navegar pela string
			JMP 	loop_toupper

		; Retorno da funcao
	retorna_toupper:
		MOV 	BX, 0
		RET
toupper 	endp

	; --------------------------------------------------
	; Imprime o resumo final contendo:
	; - Tamanho do arquivo de entrada - em bytes.
	; - Tamanho da frase - em bytes.
	; - Nome do arquivo de saida.
	; - Mensagem de sucesso.
	; - OBS: funcao "br2x" - line feed duas vezes.
	; --------------------------------------------------

resumoFinal 	proc 	near
	LEA 	BX, MsgCRLF				;	
	CALL  	printf_s				; Imprime os espacos
	CALL	br2x					;

		; Tamanho do arquivo de entrada - bytes.
	LEA 	BX, Separador			; Imprime o separador: "===============..."
	CALL 	printf_s
	CALL	br2x					; Quebra de linha dupla
	LEA 	BX, TamFileEntrada		; Carrega em BX o EA da mensagem de interacao que informa o tamanho do arquivo de entrada
	CALL 	printf_s				; Imprime [BX]
	MOV     AX, tamanhoFile			
	CALL	printNb					; Imprime o tamanho do arquivo 

	CALL	br2x					; Quebra de linha dupla

		; Tamanho da frase - em bytes.
	LEA 	BX, TamFrase			; Carrega em BX o EA da mensagem de interacao que informa o tamanho da frase
	CALL 	printf_s				; Imprime [BX]
	MOV		AX, tamanhoString	
	CALL	printNb					; Imprime o tamanho da string

	CALL 	br2x					; Quebra de linha dupla

		; Nome do arquivo de saida
	LEA 	BX, NomeFileSaida		; Carrega em BX o EA da mensagem de interacao que informa o nome do arquivo de saida
	CALL 	printf_s				; Imprime [BX]
	LEA 	BX, FileNameDst			; Carrega em BX o EA do nome do arquivo de saida
	CALL 	printf_s				; Imprime o nome do arquivo de saida ".krp"

	CALL 	br2x					; Quebra de linha dupla

		; Mensagem de sucesso
	LEA 	BX, Resultado			; Informa que o processamento ocorreu sem erros
	CALL 	printf_s				; Imprime [BX]
	CALL 	br2x

	LEA 	BX, Separador			; Imprime o separador: "===============..."	
	CALL 	printf_s
	LEA 	BX, MsgCRLF				; Imprime uma quebra de linha
	CALL  	printf_s

	RET
resumoFinal 	endp

resumoFinal65536 	proc 	near
	LEA 	BX, MsgCRLF				;	
	CALL  	printf_s				; Imprime os espacos
	CALL	br2x					;

		; Tamanho do arquivo de entrada - bytes.
	LEA 	BX, Separador			; Imprime o separador: "===============..."
	CALL 	printf_s
	CALL	br2x					; Quebra de linha dupla
	LEA 	BX, TamFileEntrada		; Carrega em BX o EA da mensagem de interacao que informa o tamanho do arquivo de entrada
	CALL 	printf_s				; Imprime [BX]

	;-----------
	;MOV     AX, tamanhoFile			
	;CALL	printNb					; Imprime o tamanho do arquivo 
	;-----------

	MOV		AX, pt1
	CALL	printNb
	MOV		AX,	pt2
	CALL	printNb

	CALL	br2x					; Quebra de linha dupla

		; Tamanho da frase - em bytes.
	LEA 	BX, TamFrase			; Carrega em BX o EA da mensagem de interacao que informa o tamanho da frase
	CALL 	printf_s				; Imprime [BX]
	MOV		AX, tamanhoString	
	CALL	printNb					; Imprime o tamanho da string

	CALL 	br2x					; Quebra de linha dupla

		; Nome do arquivo de saida
	LEA 	BX, NomeFileSaida		; Carrega em BX o EA da mensagem de interacao que informa o nome do arquivo de saida
	CALL 	printf_s				; Imprime [BX]
	LEA 	BX, FileNameDst			; Carrega em BX o EA do nome do arquivo de saida
	CALL 	printf_s				; Imprime o nome do arquivo de saida ".krp"

	CALL 	br2x					; Quebra de linha dupla

		; Mensagem de sucesso
	LEA 	BX, Resultado			; Informa que o processamento ocorreu sem erros
	CALL 	printf_s				; Imprime [BX]
	CALL 	br2x

	LEA 	BX, Separador			; Imprime o separador: "===============..."	
	CALL 	printf_s
	LEA 	BX, MsgCRLF				; Imprime uma quebra de linha
	CALL  	printf_s

	RET
resumoFinal65536 	endp

	; Imprime quebra de linha dupla
br2x	proc 	near
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	CALL 	printf_s
	RET
br2x 	endp

	; Imprime inteiros
	; OBS: funcao obtida na internet. Fonte: https://www.geeksforgeeks.org/8086-program-to-print-a-16-bit-decimal-number/ 
printNb		proc	near          
    MOV		CX, 0					; Zera os registradores CX e DX
    MOV 	DX, 0

    loop_printNb:
        CMP		AX, 0
        JE  	print_number     
        MOV 	BX, 10       
        DIV 	BX                 
        PUSH 	DX             
        INC 	CX             
        XOR 	DX, DX
        JMP 	loop_printNb
    print_number:
        CMP		CX, 0
        JE 		retorna_printNb
        POP 	DX
        ADD 	DX, 48
        MOV 	AH, 02h
        INT 	21H
        DEC 	CX
        JMP 	print_number
	retorna_printNb:
		RET
printNb		endp

	end 		