;================================================================================
;	Funcionalidades:
;		- Ler um arquivo texto (nome informado pelo usu�rio sem a extens�o .txt);
;		- Criptografar o conte�do do arquivo lido;
;		- Inserir a frase criptograda em um arquivo de sa�da (MesmoNome.krp);
;	Feito por:
;		- Guilherme Rafael Terres;
;		- Cart�o: 00338785;
;================================================================================

	.model		small 
	.stack 
	
CR		equ		0DH
LF		equ		0AH

;================================================================================
;								�REA DE DADOS
;================================================================================
	.data	
FileNameSrc		db		256 dup 		; Nome do arquivo a ser lido
FileNameDst		db		256 dup 		; Nome do arquivo a ser escrito
FileHandleSrc	dw		0				; Handler do arquivo origem
FileHandleDst	dw		0				; Handler do arquivo destino
FileBuffer		db		10 dup 			; Buffer de leitura/escrita do arquivo

	; Mensagens de instru��o e informa��o
InformaFileName		db	"Nome do arquivo de origem: ", 0
ErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
ErroCreateFile		db	"Erro na criacao do arquivo.", CR, LF, 0
ErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
ErroWriteFile		db	"Erro na escrita do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0
	
	; Constantes e vari�veis usadas na fun��o gets
MAXSTRING	equ		200
String		db		MAXSTRING dup 		

;================================================================================
;						�REA DE C�DIGO E EXECU��O (MAIN)
;================================================================================
	.code		
	.startup
	
	CALL	NomeEntrada				; Chama a fun��o NomeEntrada (entrar com o nome do arq.)
		
		; Agora o arquivo ser� aberto. Caso ocorra algum erro, ser�
		; exibida uma mensagem - "Erro na abertura do arquivo."
	LEA		DX, FileNameSrc			; O nome informado (do arquivo) � passado para DX	
	CALL	fopen					; Chama a fun��o fopen (abertura do arquivo)
	MOV		FileHandleSrc, BX		; Passa o conte�do de BX (handle do arq.) para FileHandleSrc
	JNC		Continua1				; Se n�o der carry, pula
	LEA		BX, ErroOpenFile		; Se der carry, imprime a mensagem de erro na abertura
	CALL	printf_s
	.exit	1
	
	
;================================================================================
;									FUN��ES
;================================================================================	

	; Imprime InformaFileName e recebe o nome do arquivo
NomeEntrada		proc	near
		; Imprime InformaFileName
	LEA		BX, InformaFileName		; Carrega o endere�o de InformaFileName para BX
	CALL	printf_s				; Chama a fun��o printf_s	
		
		; Recebe o nome do arquivo
	LEA		BX, FileNameSrc			; Carrega o endere�o de FileNameSrc para BX
	CALL	gets					; Chama a fun��o gets
	
		; Imprime quebra de linha
	LEA		BX, MsgCRLF				; Carrega o endere�o de MsgCRLF para BX
	CALL	printf_s				; Chama a fun��o printf_s
	
	RET								; Fim da subrotina
NomeEntrada		endp

	; Fun��o de impress�o na tela (printf)
printf_s	proc	near
	MOV		DL, [BX]				; Passa o conte�do de BX para DL, byte por byte
	CMP		DL, 0					; Enquanto o byte for != de \0, continua...
	JE		Ret_printf_s			; Sen�o, retorna da subrotina

	PUSH 	BX						; Coloca o endere�o contido em BX na pilha
	MOV		AH, 2					
	INT		21H						; Define o tipo de interrup��o
	POP		BX						; Tira o elemento do topo da pilha e p�e em BX

	INC		BX						; Incrementa para pegar o pr�ximo byte (caracter)
	JMP		printf_s				; Volta para o in�cio da fun��o
		
Ret_printf_s:
	RET								; Fim da subrotina
printf_s	endp

	; Fun��o de entrada (scanf)
gets		proc	near
	PUSH	BX								; Coloca o endere�o armazenado em BX na pilha

	MOV		AH, 0AH							; L� uma linha do teclado
	LEA		DX, String
	MOV		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	INT		21H

	LEA		SI, String+2					; Copia do buffer de teclado para o FileName
	POP		DI
	MOV		CL, String+1
	MOV		CH, 0
	MOV		AX, DS							; Ajusta ES=DS para poder usar o MOVSB
	MOV		ES, AX
	REP 	MOVSB

	MOV		byte ptr ES:[DI], 0				; Coloca marca de fim de string
	RET
gets		endp

	; Fun��o de abertura do arquivo (fopen)
fopen		proc	near
	MOV		AL, 0
	MOV		AL, 3DH
	INT		21H
	MOV		BX, AX
	RET
fopen		endp

	end 									; FIM