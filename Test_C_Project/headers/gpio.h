#ifndef GPIO_H
#define GPIO_H

#include <defines.h>

void gpio_set_dir(unsigned int gpio_num, bool dir) {
    irq_disabled();
    if(dir) GPIO_DIR |= (1 << gpio_num);
    else GPIO_DIR &= ~(1 << gpio_num);
    irq_enabled();
}

void gpio_put(unsigned int gpio_num, bool value){
    irq_disabled();
    if(value) GPIO_OUT |= (1 << gpio_num);
    else GPIO_OUT &= ~(1 << gpio_num);
    irq_enabled();
}

bool gpio_get(unsigned int gpio_num){
    return GPIO_IN & (1 << gpio_num);
}

void gpio_toggle(unsigned int gpio_num){ 
    irq_disabled();
    GPIO_OUT ^= (1 << gpio_num);
    irq_enabled();
}

#endif // GPIO_H