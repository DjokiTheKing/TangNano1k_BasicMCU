riscv64-unknown-elf-gcc -march=rv32i_zicsr -mabi=ilp32 \
    -ffreestanding -nostdlib \
    -falign-functions=4 -falign-labels=4 -falign-loops=4 -mstrict-align -msmall-data-limit=0 \
    -I./headers \
    -T ./config/link.ld -Os -o ./build/firmware.elf ./config/start.S main.c ./sources/printf.c -lgcc

riscv64-unknown-elf-objcopy -O binary ./build/firmware.elf ./build/firmware.bin
riscv64-unknown-elf-objdump -h ./build/firmware.elf
riscv64-unknown-elf-size.exe ./build/firmware.elf

truncate -s 1048576 ./build/firmware.bin