```assembly
; Define memory addresses
.equ BASE_ADDR = 0x200    ; Base of the ASCII character table
.equ SEQ_ADDR = 0x300     ; Start of the sequence space
.equ END_ADDR = 0x400     ; End of the sequence space
.equ TRIGGER = 0x1C       ; Code to start reading the sequence
.equ SAVE_COUNT = 0x1D
.equ CHAR_FREQ = 0x1E
.equ SEQ_END_ADDR = 0x500 ; Address where the end pointer of the sequence is stored
.equ CHAR_COUNT = 0x401

.cseg
.org 0x0000
rjmp RESET                ; Program entry point

RESET:
    ; Initial configuration
    ldi r16, 0x00
    out DDRC, r16          ; Configure all PORTC pins as input
    ldi r16, 0xFF
    out PORTC, r16         ; Enable pull-up resistors on PORTC

    ; Initialize ASCII character table at BASE_ADDR
    ldi r16, HIGH(BASE_ADDR) ; Load high byte of base address into register ZH
    out RAMPZ, r16           ; Set the page register for IRAM memory
    ldi r30, LOW(BASE_ADDR)  ; Load low byte into register ZL
    ldi r31, HIGH(BASE_ADDR) ; Load high byte into register ZH

    ; Store uppercase characters A-Z (0x41-0x5A)
    ldi r16, 0x41            ; First character 'A'
ALPHA_UPPER_LOOP:
    st Z+, r16               ; Store character at the current address and increment Z
    inc r16                  ; Next character
    cpi r16, 0x5B            ; Check if the end ('Z' + 1) is reached
    brne ALPHA_UPPER_LOOP    ; If not, repeat the loop

    ; Store lowercase characters a-z (0x61-0x7A)
    ldi r16, 0x61            ; First character 'a'
ALPHA_LOWER_LOOP:
    st Z+, r16               ; Store character at the current address and increment Z
    inc r16                  ; Next character
    cpi r16, 0x7B            ; Check if the end ('z' + 1) is reached
    brne ALPHA_LOWER_LOOP    ; If not, repeat the loop

    ; Store digits 0-9 (0x30-0x39)
    ldi r16, 0x30            ; First digit '0'
DIGIT_LOOP:
    st Z+, r16               ; Store digit at the current address and increment Z
    inc r16                  ; Next digit
    cpi r16, 0x3A            ; Check if the end ('9' + 1) is reached
    brne DIGIT_LOOP          ; If not, repeat the loop

    ; Store the space character (0x20)
    ldi r16, 0x20            ; ASCII code for space
    st Z+, r16               ; Store the space character

    ; Store the <ESC> command (0x1B)
    ldi r16, 0x1B            ; ASCII code for <ESC>
    st Z+, r16               ; Store the <ESC> command

    ; Start the main loop
    rjmp MAIN_LOOP

MAIN_LOOP:
    in r16, PIND             ; Read the value from the input port
    cpi r16, TRIGGER         ; Check if the start code was received
    brne MAIN_LOOP           ; If not, continue in the loop

    rcall READ_SEQUENCE      ; Call the routine to read the sequence
    rcall BUBBLE_SORT        ; Sort the read sequence
    rjmp MAIN_LOOP           ; Return to the main loop

READ_SEQUENCE:
    ldi r30, LOW(SEQ_ADDR)    ; Pointer Z to the beginning of the sequence
    ldi r31, HIGH(SEQ_ADDR)
    clr r22                   ; Clear the character counter

READ_CHAR:
    in r16, PIND              ; Read a character from the input
    cpi r16, 0x1B             ; Check if it is <ESC>
    breq END_SEQUENCE         ; If yes, end the sequence

    ; Check if the character is valid
    cpi r16, 0x20             ; Valid characters start at 0x20
    brlo READ_CHAR            ; If less than 0x20, ignore and read another
    cpi r16, 0x7B             ; Valid characters end at 0x7F
    brsh READ_CHAR            ; If greater or equal to 0x7F, ignore and read another

    inc r22                   ; Increment the character counter
    st Z+, r16                ; Store the character in memory and increment Z

    ; Check if memory reached the END_ADDR limit
    cpi r30, LOW(END_ADDR)    ; Check if the low byte of pointer Z reached the limit
    brne READ_CHAR            ; If not, continue reading
    cpi r31, HIGH(END_ADDR)   ; Check if the high byte of pointer Z reached the limit
    brne READ_CHAR            ; If not, continue reading

END_SEQUENCE:
    ret                       ; Return from the subroutine

; Bubble Sort routine
BUBBLE_SORT:
    ldi r26, LOW(SEQ_ADDR)  ; Pointer X to the start of the sequence
    ldi r27, HIGH(SEQ_ADDR) ; High byte of pointer X

    ldi r28, LOW(END_ADDR - 1) ; Pointer Y to the end of the sequence
    ldi r29, HIGH(END_ADDR - 1); High byte of pointer Y

BUBBLE_OUTER_LOOP:
    clr r16                 ; Flag to check if a swap occurred
    mov r30, r26            ; Pointer Z starts at the beginning (copy of X)
    mov r31, r27

BUBBLE_INNER_LOOP:
    ld r18, Z               ; Load the current element
    ld r19, Z+              ; Load the next element

    cp r18, r19             ; Compare the two elements
    brlo NO_SWAP            ; If the current is smaller, do not swap

    ; Swap elements
    st -Z, r19              ; Store the next element in place of the current
    st Z, r18               ; Store the current element in place of the next
    ldi r16, 1              ; Mark that a swap occurred

NO_SWAP:
    cpi r30, LOW(END_ADDR - 1); Check if it reached the end of the sequence
    brne BUBBLE_INNER_LOOP  ; Continue the inner loop if not finished

    dec r29                 ; Reduce the range of the end of the list
    cpi r29, HIGH(SEQ_ADDR) ; Check if the end exceeded the beginning
    brlo BUBBLE_DONE        ; Exit the loop if finished

    tst r16                 ; Check if a swap occurred in the iteration
    brne BUBBLE_OUTER_LOOP  ; If a swap occurred, repeat the outer loop

BUBBLE_DONE:
    ret                     ; Return to the main program
```
