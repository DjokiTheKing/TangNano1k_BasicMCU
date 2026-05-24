#ifndef TIMER_H
#define TIMER_H

#include <defines.h>

void timer_interrupt_disable();

void (*__TIMER_IRQ_CALLBACK)(void) = nullptr;
uint32_t __TIMER_REPEAT_TIME = 0;

__attribute__((interrupt)) void __timer_isr_once(void) {
    TIMER_CMP = 0;
    timer_interrupt_disable();
    __TIMER_IRQ_CALLBACK();
}

__attribute__((interrupt)) void __timer_isr_repeating(void) {
    TIMER_CMP += __TIMER_REPEAT_TIME;
    __TIMER_IRQ_CALLBACK();
}

void __timer_interrupt_enable(uint32_t target_isr_addr){
    asm volatile ("csrw mtvec, %0" : : "r"(target_isr_addr));
    TIMER_IRQ |= 1;
    asm volatile ("csrs mie, %0": :"r" (1 << 7));
    irq_enabled();
}

void timer_interrupt_disable(){
    irq_disabled();
    asm volatile ("csrc mie, %0": :"r" (1 << 7));
    TIMER_IRQ &= ~1;
}

void timer_setup_interrupt_at_time(uint32_t time, void (*irq_callback)(void)) {
    TIMER_CMP = time;
    __TIMER_IRQ_CALLBACK = irq_callback;
    __timer_interrupt_enable((uint32_t)__timer_isr_once);
}

void timer_setup_repeating_interrupt(uint32_t time, void (*irq_callback)(void)) {
    TIMER_CMP = TIMER_CNT+time;
    __TIMER_REPEAT_TIME = time;
    __TIMER_IRQ_CALLBACK = irq_callback;
    __timer_interrupt_enable((uint32_t)__timer_isr_repeating);
}

inline uint32_t get_timer() {
    return TIMER_CNT;
}

void sleep_ms(uint32_t n){
    uint32_t t = get_timer() + n;
    while(get_timer() < t);
}

#endif // TIMER_H