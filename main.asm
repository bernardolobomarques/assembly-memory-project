;
; trabalhoAP2GP1.asm
;
; Alunos : Michel de Melo Guimarães - 202401569852 - TA
;		   Bernardo Lobo Marques - 202401709433 - TA
;		   Bernado Moreira - 202401500283 - TA
;		   Pedro Macedo - 202401318728 - TA
;		   Gustavo Salvador - 202402875361 - TA
;          João Victor Bathomarco - 202302902448 - TA

; Define os endereços na memória
.equ BASE_ADDR = 0x200    ; Base da tabela de caracteres ASCII
.equ SEQ_ADDR = 0x300     ; Início do espaço para sequências
.equ END_ADDR = 0x400     ; Fim do espaço para sequências
.equ TRIGGER = 0x1C       ; Código para iniciar a leitura de sequência
.equ SAVE_COUNT = 0x1D
.equ CHAR_FREQ = 0x1E
.equ SEQ_END_ADDR = 0x500 ; Endereço onde armazenamos o ponteiro final da sequência
.equ CHAR_COUNT = 0x401


.cseg
.org 0x0000
rjmp RESET                ; Ponto de entrada do programa

RESET:
    ; Configuração inicial
    ldi r16, 0x00
    out DDRC, r16          ; Configura todos os pinos do PORTC como entrada
    ldi r16, 0xFF
    out PORTC, r16         ; Ativa resistores pull-up no PORTC

    ; Inicializar tabela de caracteres ASCII em BASE_ADDR
    ldi r16, HIGH(BASE_ADDR) ; Carrega a parte alta do endereço base no registrador ZH
    out RAMPZ, r16           ; Configura o registrador de página para a memória IRAM
    ldi r30, LOW(BASE_ADDR)  ; Carrega a parte baixa no registrador ZL
    ldi r31, HIGH(BASE_ADDR) ; Carrega a parte alta no registrador ZH
    
    ; Armazenar caracteres maiúsculos A-Z (0x41-0x5A)
    ldi r16, 0x41            ; Primeiro caractere 'A'
ALPHA_UPPER_LOOP:
    st Z+, r16               ; Armazena o caractere no endereço atual e incrementa Z
    inc r16                  ; Próximo caractere
    cpi r16, 0x5B            ; Verifica se alcançou o fim ('Z' + 1)
    brne ALPHA_UPPER_LOOP    ; Se não, repete o loop

    ; Armazenar caracteres minúsculos a-z (0x61-0x7A)
    ldi r16, 0x61            ; Primeiro caractere 'a'
ALPHA_LOWER_LOOP:
    st Z+, r16               ; Armazena o caractere no endereço atual e incrementa Z
    inc r16                  ; Próximo caractere
    cpi r16, 0x7B            ; Verifica se alcançou o fim ('z' + 1)
    brne ALPHA_LOWER_LOOP    ; Se não, repete o loop

    ; Armazenar dígitos 0-9 (0x30-0x39)
    ldi r16, 0x30            ; Primeiro dígito '0'
DIGIT_LOOP:
    st Z+, r16               ; Armazena o dígito no endereço atual e incrementa Z
    inc r16                  ; Próximo dígito
    cpi r16, 0x3A            ; Verifica se alcançou o fim ('9' + 1)
    brne DIGIT_LOOP          ; Se não, repete o loop

    ; Armazenar o espaço em branco (0x20)
    ldi r16, 0x20            ; Código ASCII do espaço em branco
    st Z+, r16               ; Armazena o espaço em branco

    ; Armazenar o comando <ESC> (0x1B)
    ldi r16, 0x1B            ; Código ASCII do <ESC>
    st Z+, r16               ; Armazena o comando <ESC>

    ; Inicia o loop principal
    rjmp MAIN_LOOP

MAIN_LOOP:
    in r16, PIND             ; Lê o valor da porta de entrada
    cpi r16, TRIGGER         ; Verifica se o código para iniciar foi recebido
    brne MAIN_LOOP           ; Se não, continua no loop

    rcall READ_SEQUENCE      ; Chama a rotina para leitura da sequência
    rcall BUBBLE_SORT        ; Ordena a sequência lida
    rjmp MAIN_LOOP           ; Retorna para o loop principal

READ_SEQUENCE:
    ldi r30, LOW(SEQ_ADDR)    ; Ponteiro Z para o início da sequência
    ldi r31, HIGH(SEQ_ADDR)
    clr r22                   ; Zera o contador de caracteres

READ_CHAR:
    in r16, PIND              ; Lê um caractere da entrada
    cpi r16, 0x1B             ; Verifica se é <ESC>
    breq END_SEQUENCE         ; Se sim, termina a sequência

    ; Verifica se o caractere é válido
    cpi r16, 0x20             ; Caracteres válidos começam em 0x20
    brlo READ_CHAR            ; Se menor que 0x20, ignora e lê outro
    cpi r16, 0x7B             ; Caracteres válidos terminam em 0x7F
    brsh READ_CHAR            ; Se maior ou igual a 0x7F, ignora e lê outro

    inc r22                   ; Incrementa o contador de caracteres
    st Z+, r16                ; Armazena o caractere na memória e incrementa Z

    ; Verifica se a memória atingiu o limite de END_ADDR
    cpi r30, LOW(END_ADDR)    ; Verifica se a parte baixa do ponteiro Z atingiu o limite
    brne READ_CHAR            ; Se não, continua lendo
    cpi r31, HIGH(END_ADDR)   ; Verifica se a parte alta do ponteiro Z atingiu o limite
    brne READ_CHAR            ; Se não, continua lendo

END_SEQUENCE:
    ret                       ; Retorna da sub-rotina

; Rotina de Bubble Sort
BUBBLE_SORT:
    ldi r26, LOW(SEQ_ADDR)  ; Ponteiro X para o início da sequência
    ldi r27, HIGH(SEQ_ADDR) ; Parte alta do ponteiro X

    ldi r28, LOW(END_ADDR - 1) ; Ponteiro Y para o final da sequência
    ldi r29, HIGH(END_ADDR - 1); Parte alta do ponteiro Y

BUBBLE_OUTER_LOOP:
    clr r16                 ; Flag para verificar se houve troca
    mov r30, r26            ; Ponteiro Z começa no início (cópia de X)
    mov r31, r27

BUBBLE_INNER_LOOP:
    ld r18, Z               ; Carrega o elemento atual
    ld r19, Z+              ; Carrega o próximo elemento

    cp r18, r19             ; Compara os dois elementos
    brlo NO_SWAP            ; Se o atual for menor, não troca

    ; Trocar elementos
    st -Z, r19              ; Armazena o próximo no lugar do atual
    st Z, r18               ; Armazena o atual no lugar do próximo
    ldi r16, 1              ; Marca que houve troca

NO_SWAP:
    cpi r30, LOW(END_ADDR - 1); Verifica se chegou ao final da sequência
    brne BUBBLE_INNER_LOOP  ; Continua o loop interno se não terminou

    dec r29                 ; Reduz o alcance do final da lista
    cpi r29, HIGH(SEQ_ADDR) ; Verifica se o final ultrapassou o início
    brlo BUBBLE_DONE        ; Sai do loop se terminado

    tst r16                 ; Verifica se houve troca na iteração
    brne BUBBLE_OUTER_LOOP  ; Se houve troca, repete o loop externo

BUBBLE_DONE:
    ret                     ; Retorna ao programa principal