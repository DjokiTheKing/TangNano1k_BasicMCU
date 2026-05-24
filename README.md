# TangNano1k_BasicMCU

This is my first verilog project, as such, i wanted to have fun.\
Over a week i set this up, ServCore from [olofk](https://github.com/olofk/serv.git), basic bus mux, bus arbiter, gpio, timer, spi flash, sram(using gowins bsram interface), uart(tx only).

The C test works fine, and i plan to have some more fun in the future with this.

## This is the resource usage on the TangNano1k fpga board:

Logic	1080/1152	94%:
- LUT,ALU,ROM16	864(761 LUT, 103 ALU, 0 ROM16)
- SSRAM(RAM16)	36
    
Register	524/957	55%:
- Logic Register as Latch	0/864	0%
- Logic Register as FF	522/864	61%
- I/O Register as Latch	0/93	0%
- I/O Register as FF	2/93	3%
    
CLS	566/576	99%

I/O Port	25/41	61%

I/O Buf	25:
- Input Buf	2
- Output Buf	3
- Inout Buf	20
     
BSRAM	4 SP 100%

## Testing setup:
<img width="2510" height="2296" alt="IMG_20260524_182148" src="https://github.com/user-attachments/assets/5e83e7b8-a8dd-41c5-b259-4066b3e82638" />
