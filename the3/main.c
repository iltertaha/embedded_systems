/* In the implementation , used round-robin with interrupts method.
    In the round robin while(1) loop , implemented 5 states, with state machine approach.
    In the ISR routine , have routines for TMR1, TMR0, RB4, AD converter and TMR2 interrupts.
    Moreover , divided the ISR routine to two parts, one parts is for the in game part, the other parts is for the end game part.
    Until 5 seconds passes or player guesses the special number right the ISR works wirh the in game part, after one of those conditions met, 
    , close all interrupts other then TMR1 interrupt and set it to count down for 500ms.
    In the main loop state 0 is initialization state that initializes the ISRs, and interrupt sources. (init function includes how the registers and used variables are set).
    After this state the state is changed to state 1 ready state where interrupts from TIMER0, and RB4 changes the state. 
    Whenever 50 ms passes, TMR0IF is set, and in the related interrupt routine the AD converter is started.
    After conversion finishes ADIF flag is set, and the adc_value is read in the ISR routine and the state is changed to state 2.
    In the state 2 the digit counterpart of adc_value is computed and the 7segmnet display is updated, state is changed to state 1.
    Whenever RB4 button state changes, RBIF flag is set and in the ISR Tımer2 module is started. 
    The use of Timer2 is for debouncing. Timer2 count 10ms and if the RBIF flag is set before 10 ms passes, timer2 is reset to count 10 ms again. 
    If there is no change in RB4 and 10 ms passes, that means the signal is persistant and if it is a push action the state changes to state 3.
    In state 3, the guessed number and the special number is compared. If they are not equal cde leds are handled to show a hint.
    If they are equal, the state is changed to state 4. In this state, interrupts from all sources other than timer1 is disabled. And timer1 is updated to count 500ms.
    In this state if the game ended with a correct guess or 5 seconds times up is also handled. In the end of this state the cde leds are cleared and the state is changed to state 5.
    In state 5, the 7 segment display is updated with the special number and blinking of the display is handled.
    Other than correct guessing, Timer1 interrupt is used before the end game state to count 5 seconds. If 5 seconds pass, the state is also changed to state 4.
 */

#pragma config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

#include <xc.h>
#include "breakpoints.h"

int count_timer1; // used as a postscaler for timer 1 (for 5 seconds and 500 ms)
int count_timer2; // used as a postscaler for timer 2 (10 ms)
int count_blink; // number of times the display blinked
int state_machine; // state of the main loop
int end; // flag for ISR routine for dividing in game and end game states
int number_sho,d; // if the spacial number sho,d in the 7 segment display or not
int correct_end; // flag for if game finished with a correct guess 
int guess; // player's guess adc value to digit mapping
int RB4_value; // flag for RB4 is pushed (1 when pushed)

void __interrupt() ISR(){
    if(!end){ // in game phase
        if(TMR1IF){
            if(count_timer1 == 95){ // 5 seconds passed 
                state_machine = 4; 
            }
            else{
                count_timer1++;
            }
            TMR1IF = 0;
        }
        if(TMR0IF){ // routine for timer0 interrupt counts 50 ms
            TMR0H = 11;
            TMR0L = 0;
            GO = 1; // start AD conversion
            TMR0IF = 0;
        }
        if(ADIF){ // routine for AD conversion finished interrupt
            adc_value = ADRESL + (ADRESH << 8); // read adc value
            adc_complete();
            state_machine = 2; 
            ADIF = 0;
        }
        if(RBIF){ // routine for RB4 buttton press
            RB4_value = PORTBbits.RB4;
            count_timer2 = 0; // set timer2 counter for counting 10 ms
            TMR2 = 18; // restart the clock count
            TMR2ON = 1; // open timer2 
            RBIF = 0;
        }
        if(TMR2IF){
            if(count_timer2 == 25){
                if(RB4_value){ // check the value again to decide if it was a push operation that persisted for 10 ms.
                    state_machine = 3;
                    rb4_handled();
                }
                TMR2ON = 0; // close timer2 
            }
            else{
                count_timer2++;
            }
            TMR2 = 18;
            TMR2IF = 0;
        } 
    }
    else{ // end game phase
        if(TMR1IF){ // game over ISR routine, count for 500 ms with timer1, in the end game phase other interrupt sources are closed.
            if(count_timer1 == 9){ // 500 ms passed
                state_machine = 5;
                count_timer1 = 0;
            }
            else{
                count_timer1++;
            }
            TMR1H = 12;
            TMR1L = 0;
            TMR1IF = 0;
        }
    }
}

void end_init(){ // initializations for end game state
    GIE = 0;
    // Disable TIMER0, PORTB, AD conversion interrupts
    TMR0ON = 0;
    TMR0IE = 0;
    TMR0IF = 0;
    RBIE = 0;
    RBIF = 0;
    ADON = 0;
    ADIE = 0;
    // Initialize TIMER1 for 500ms
    TMR1ON = 0;
    count_timer1 = 0;
    TMR1H = 12;
    TMR1L = 0;
    TMR1ON = 1;
    state_machine = 5;
    GIE = 1;
}

void update_cdeleds(){ // update cdeleds to give hint
    PORTD = 0b00001111;
    PORTC = 0;
    PORTE = 0;
    if(guess < special_number()){
        PORTCbits.RC1 = 1;
        PORTEbits.RE1 = 1;
    }
    else{
        PORTCbits.RC2 = 1;
        PORTEbits.RE2 = 1;
    }
    latcde_update_complete();
}

void update_7segmentdisplay(){ // update 7segment display with guess number, guess is used for guessed value in in-game phase and it is used for special number in the end-game phase
    PORTHbits.RH0 = 0; PORTHbits.RH1 = 0; PORTHbits.RH2 = 0; PORTHbits.RH3 = 1;
    switch(guess){
        case 0:{
            PORTJ = 0b00111111;
            break;
        }
        case 1:{
            PORTJ = 0b00000110;
            break;
        }
        case 2:{
            PORTJ = 0b01011011;
            break;
        }
        case 3:{
            PORTJ = 0b01001111;
            break;
        }
        case 4:{
            PORTJ = 0b01100110;
            break;
        }
        case 5:{
            PORTJ = 0b01101101;
            break;
        }
        case 6:{
            PORTJ = 0b01111101;
            break;
        }
        case 7:{
            PORTJ = 0b00000111;
            break;
        }
        case 8:{
            PORTJ = 0b01111111;
            break;
        }
        case 9:{
            PORTJ = 0b01101111;
            break;
        }
    }
    latjh_update_complete();
}

void init(){
    // Disable all interrupts
    GIE = 0;
    // Initialize variables
    count_timer1 = 0;
    count_timer2 = 0;
    count_blink = 0;
    state_machine = 1;
    end = 0;
    correct_end = 0;
    number_sho,d = 0;
    // Enable peripheral interrupts
    PEIE = 1;
    // Make PORTC-D-E output
    TRISC = 0;
    TRISD = 0;
    TRISE = 0;
    TRISH = 0b11110000;
    TRISJ = 0b00000000;
    // Clear PORTC-D-E
    LATC = 0;
    LATD = 0;
    LATE = 0;
    // PORTB on-change interrupt configuration
    TRISB = 0b00010000;
    RBIE = 1;
    // TIMER0 configuration
    T0CON = 0b00000010;
    TMR0H = 11;
    TMR0L = 0;
    TMR0IF = 0;
    TMR0IE = 1;
    // TIMER1 configuration
    T1CON = 0b11111000;
    TMR1H = 150;
    TMR1L = 0;
    TMR1IF = 0;
    TMR1IE = 1;
    // TIMER2 configuraition
    T2CON = 0b00000011; // Prescaler 1:16
    TMR2IF = 0;
    TMR2IE = 1;
    // ADC configuration
    ADCON1 = 0b00000000;
    ADCON0 = 0b00110000;
    ADCON2 = 0b10101110;
    // Start timers and ADC
    TMR0ON = 1;
    TMR1ON = 1;
    ADON = 1;
    ADIF = 0;
    ADIE = 1;
    // Enable all interrupts
    GIE = 1;
}

void main(void) {
    while(1){
        switch(state_machine){
            case 0:{ // Initialization
                init();
                init_complete();
                break;
            }
            case 1:{ // Ready
                break;
            }
            case 2:{ // A-D value to digit and update display
                state_machine = 1;
                if(adc_value <= 102){
                    guess = 0;
                }
                else{
                    guess = adc_value / 102;
                }
                update_7segmentdisplay();
                break;
            }
            case 3:{ // comparison bet,en guessed and special numbers
                state_machine = 1;
                if(guess == special_number()){
                    correct_end = 1;
                    state_machine = 4;
                }
                else{
                    update_cdeleds();
                }
                break;
            }
            case 4:{ // Start of the end game phase
                end = 1;
                if(correct_end){ // shceck how game ended
                    correct_guess();
                }
                else{
                    game_over();
                }
                LATC = 0; //  clear leds
                LATD = 0;
                LATE = 0;
                latcde_update_complete();
                guess = special_number();  // since guess is used for updating 7 segment display, to show special number in the display the guess is updated with special number.
                end_init(); // handle initializations for end game phase
                break;
            }
            case 5:{ // Handle blinking
                state_machine = 1;
                if(count_blink){ 
                    hs_passed();
                }
                if(count_blink == 4){ // 2 seconds passed all blinks handled
                    restart();
                    state_machine = 0; // restart the game
                    break;
                }
                if(number_sho,d){ // if special number is sho,d clear the display
                    PORTJ = 0;
                    latjh_update_complete();
                    count_blink++;
                    number_sho,d = 0;
                }
                else{// if the display is cleared show the special number
                    update_7segmentdisplay();
                    count_blink++;
                    number_sho,d = 1;
                }
                break;
            }
        }
    }
    return;
}