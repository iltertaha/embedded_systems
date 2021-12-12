#include <p18f8722.inc>

    ; CONFIG1H
    CONFIG OSC=HSPLL, FCMEN=OFF, IESO=OFF,PWRT=OFF,BOREN=OFF, WDT=OFF, MCLRE=ON, LPT1OSC=OFF, LVP=OFF, XINST=OFF, DEBUG=OFF

    UDATA_ACS
delay_counter1	res 1	; used in delay
delay_counter2	res 1	; used in delay
delay_counter3	res 1	; used in delay
firstpress res 1 ; checks the operation selection started
state res 1	; controlled by RB5 button
ra4_pressed res 1
re3_pressed res 1
topla_flag res 1
cikar_flag res 1
wait_flag res 1
cont_flag res 1
current_b res 1
current_c res 1
result res 1
re3_led_pressed res 1
 
;org 0x00
;goto START

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE	; let linker place main program
 
    
START:
    call INIT ; init vars and ports
    



MAIN_LOOP:
    
    
    call check_re3
    clrf WREG
    cpfseq re3_pressed
    goto re3_cont ; if re3 pressed and released
    goto re3_wait ; if not pressed
    
    
re3_wait:
    BSF wait_flag,0
    BCF cont_flag,0
    
    call check_ra4 
    
    clrf WREG
    ;cpfseq ra4_pressed
    ;goto ; if ra4 pressed
    goto MAIN_LOOP ; if ra4 not pressed
    
    
    
re3_cont:
    clrf WREG
    cpfseq firstpress; check whether ra4 is pressed at least once
    goto safe_to_cont ; if pressed
    clrf re3_pressed
    goto MAIN_LOOP ; if not pressed
safe_to_cont:
    BSF cont_flag,0
    BCF wait_flag,0
    
    clrf WREG
    cpfseq state
    goto topla_b ; if state is 1
    goto cikar ; if state is 0
 
    
cikar:
    goto topla_b
topla_b:
    call checkled_re3;
    clrf WREG
    cpfseq re3_led_pressed
    goto re3_ledb_cont
    goto re3_ledb_wait
    
re3_ledb_wait:
    call check_ledb_re4
    goto topla_b

re3_ledb_cont:
    clrf re3_led_pressed
    goto topla_c

    
    
    goto topla_b
    
topla_c:
    clrf re3_led_pressed
    call checkled_re3;
    clrf WREG
    cpfseq re3_led_pressed
    goto re3_ledc_cont
    goto re3_ledc_wait
    
re3_ledc_wait:
    call check_ledc_re4
    goto topla_c

re3_ledc_cont:
    goto resulter
   

    goto topla_c
    
    
    
resulter:
    
    CLRF WREG
    cpfseq state
    goto result_topla ; if state is 1
    goto result_cikar ; if state is 0
    
    
    
result_topla:
    CLRF WREG
    CLRF STATUS
    MOVF   current_b, 0; move b to wreg
    ADDWF    current_c,0 ; add c to b and store in wreg
    goto led_inc_finalizer
   
    
result_cikar:
    CLRF WREG 
    CLRF STATUS
    MOVF current_b,0 ; move b to wreg
    CPFSGT current_c, 0 ; if current_c is greater than current_b skip
    goto b_eksi_c ; b buyuktur c den
    goto c_eksi_b ; c buyuktur b den
    

c_eksi_b:
    SUBWF   current_c, 0 ; subtract current_b from current_c and store in wreg
    goto led_inc_finalizer
b_eksi_c:
    MOVF current_c,0 ; move c to wreg
    SUBWF current_b,0 ; substract current_c from current_b and store in wreg
    goto led_inc_finalizer
    
    
    
led_inc_finalizer:

    xorlw     b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE1, jump to LABEL1
    goto yak_1     
    xorlw     b'00000010'^ b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE2, jump to LABEL2
    goto yak_2 
    xorlw     b'00000011'^b'00000010'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    goto yak_3 
    xorlw     b'00000100'^b'00000011'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    goto yak_4 
    xorlw     b'00000101'^b'00000100'
    btfsc     STATUS, Z                ; If SWITCH = CASE1, jump to LABEL1
    goto yak_5 
    xorlw     b'00000110'^ b'00000101'
    btfsc     STATUS, Z                ; If SWITCH = CASE2, jump to LABEL2
    goto yak_6 
    xorlw     b'00000111'^b'00000110'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    goto yak_7 
    xorlw     b'00001000'^b'00000111'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    goto yak_8
    xorlw     b'00000000'^b'00001000'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    goto yak_0

yak_1:
    MOVLW b'00000001'
    MOVWF LATD
    goto delayer
yak_2:
    MOVLW b'00000011'
    MOVWF LATD
    goto delayer
yak_3:
    MOVLW b'00000111'
    MOVWF LATD
    goto delayer
yak_4:
    MOVLW b'00001111'
    MOVWF LATD
    goto delayer
yak_5:
    MOVLW b'00011111'
    MOVWF LATD
    goto delayer
yak_6:
    MOVLW b'00111111'
    MOVWF LATD
    goto delayer
yak_7:
    MOVLW b'01111111'
    MOVWF LATD
    goto delayer
yak_8:
    MOVLW b'11111111'
    MOVWF LATD
    goto delayer
yak_0:
    MOVLW b'00000000'
    MOVWF LATD
    goto delayer

delayer:
    CALL delay_500
    CALL delay_500
    
    CLRF LATB
    CLRF LATC
    CLRF LATD
    
    
    clrf delay_counter1	; used in delay
    clrf delay_counter2	; used in delay
    clrf delay_counter3	; used in delay
    clrf firstpress ; checks the operation selection started
    clrf state 	; controlled by RB5 button
    clrf ra4_pressed 
    clrf re3_pressed
    clrf topla_flag 
    clrf cikar_flag 
    clrf wait_flag 
    clrf cont_flag 
    clrf current_b 
    clrf current_c 
    clrf result 
    clrf re3_led_pressed 
    GOTO MAIN_LOOP ; loop forever
    

    
    
INIT:
    clrf delay_counter1	; used in delay
    clrf delay_counter2	; used in delay
    clrf delay_counter3	; used in delay
    clrf firstpress ; checks the operation selection started
    clrf state 	; controlled by RB5 button
    clrf ra4_pressed 
    clrf re3_pressed
    clrf topla_flag 
    clrf cikar_flag 
    clrf wait_flag 
    clrf cont_flag 
    clrf current_b 
    clrf current_c 
    clrf result 
    clrf re3_led_pressed 
    
    CLRF PORTA
    MOVLW 0xFF
    MOVWF ADCON1
    MOVLW b'00010000'
    MOVWF TRISA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD
    CLRF PORTE
    CLRF TRISB
    MOVLW b'00011000'
    MOVWF TRISE
    CLRF TRISC
    CLRF TRISD
    
    
    MOVLW 0x0F
    MOVWF LATB
    MOVWF LATC
    MOVLW 0xFF
    MOVWF LATD
    CALL delay_500 ;  1 sec delay
    CALL delay_500
    CLRF LATB ; turn off leds
    CLRF LATC
    CLRF LATD
    
    
    return
    
    

    
    
delay_500 ; 500 ms delay
    movlw b'00011011'
    movwf delay_counter1
    movlw b'01011111'
    movwf delay_counter2
    movlw b'00000011'
    movwf delay_counter3
    nop


for1:
    decfsz delay_counter1
    goto for2
    return
for2:
    decfsz delay_counter2
    goto for3
    goto for1
for3:
    decfsz delay_counter3
    goto for3
    goto for2
    

    
check_re3: 
    BTFSS PORTE,3
    return
_debounce1:
    BTFSC PORTE,3
    goto _debounce1
    BSF re3_pressed, 0
    return

check_ra4: 
    BTFSS PORTA,4
    return
_debounce2:
    BTFSC PORTA,4
    goto _debounce2
    BTG state,0
    BSF firstpress,0
    return
	
checkled_re3: 
    BTFSS PORTE,3
    return
_debounce3:
    BTFSC PORTE,3
    goto _debounce3
    BSF re3_led_pressed, 0
    return

check_ledb_re4: 
    BTFSS PORTE,4
    return
_debounce4:
    BTFSC PORTE,4
    goto _debounce4
    movlw b'00000100'

    cpfseq current_b ; 
    goto isnotfour ; if current_b is not 4
    goto isfour ; if current_b is 4

isfour:
    clrf current_b ; if b is 4
    movff current_b,LATB
    return

isnotfour:
led_inc:
    INCF  current_b, 1
    CLRF STATUS
    movf      current_b, w
    xorlw     b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE1, jump to LABEL1
    bsf     PORTB,0
    xorlw     b'00000010'^ b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE2, jump to LABEL2
    bsf     PORTB,1
    xorlw     b'00000011'^b'00000010'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    bsf     PORTB,2
    xorlw     b'00000100'^b'00000011'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    bsf     PORTB,3
    return
	
	
check_ledc_re4: 
    BTFSS PORTE,4
    return
_debounce5:
    BTFSC PORTE,4
    goto _debounce5
    movlw b'00000100'

    cpfseq current_c ; 
    goto isnotfour2 ; if current_b is not 4
    goto isfour2 ; if current_b is 4

isfour2:
    clrf current_c; if b is 4
    movff current_c,LATC
    return

isnotfour2:
led_inc2:
    INCF  current_c, 1
    CLRF STATUS
    movf      current_c, w
    xorlw     b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE1, jump to LABEL1
    bsf     PORTC,0
    xorlw     b'00000010'^ b'00000001'
    btfsc     STATUS, Z                ; If SWITCH = CASE2, jump to LABEL2
    bsf     PORTC,1
    xorlw     b'00000011'^b'00000010'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    bsf     PORTC,2
    xorlw     b'00000100'^b'00000011'
    btfsc     STATUS, Z                ; If SWITCH = CASE3, jump to LABEL3
    bsf     PORTC,3
    return

    end
	