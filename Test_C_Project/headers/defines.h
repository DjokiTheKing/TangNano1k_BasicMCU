#ifndef DEFINES_H
#define DEFINES_H

#include <stdint.h>

#define GPIO_OUT *((volatile unsigned int*)0x04000000)
#define GPIO_IN *((volatile unsigned int*)0x04000004)
#define GPIO_DIR *((volatile unsigned int*)0x04000008)
#define GPIO_NUM 20

#define TIMER_CNT *((volatile unsigned int*)0x04000010)
#define TIMER_CMP *((volatile unsigned int*)0x04000014)
#define TIMER_IRQ *((volatile unsigned int*)0x04000018)

#define UART_TX *((volatile unsigned int*)0x04000020)
#define UART_CONTROL *((volatile unsigned int*)0x04000024)

#define LED_BUILTIN_RED_PIN 16
#define LED_BUILTIN_GREEN_PIN 17
#define LED_BUILTIN_BLUE_PIN 18
#define BUTTON_BUILTIN_PIN 19

#define PRINTF_SUPPORT_FLOAT

#define irq_disabled() __asm__ volatile ("csrci mstatus, 0x8")
#define irq_enabled()  __asm__ volatile ("csrsi mstatus, 0x8")

#endif // DEFINES_H