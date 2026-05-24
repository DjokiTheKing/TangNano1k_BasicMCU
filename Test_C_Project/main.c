#include <printf.h>
#include <gpio.h>
#include <timer.h>

void timer_isr(){
    gpio_toggle(1);
}

int main(){
    UART_CONTROL = 1;

    gpio_set_dir(1, true);
    gpio_put(1, true);

    timer_setup_repeating_interrupt(269, timer_isr);

    gpio_set_dir(BUTTON_BUILTIN_PIN, false);

    float test = 1.2f;

    while(true){
        if(!gpio_get(BUTTON_BUILTIN_PIN)) test += test;

        printf("Hello, World!\n");
        printf("LED   : %d\n", gpio_get(1));
        printf("BUTTON: %d\n", gpio_get(BUTTON_BUILTIN_PIN));
        printf("TEST F: %.2f\n\n", test);
        sleep_ms(1000);
    }

    return 0;
}