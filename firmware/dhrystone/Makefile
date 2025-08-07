
#TOOLCHAIN_PATH=/usr/bin/
#TOOLCHAIN_PATH=/usr/local/bin
TOOLCHAIN_PATH=/opt/riscv32imc/bin/
# TOOLCHAIN_PATH=/ef/apps/bin/

# Set the prefix for `riscvXX-unknown-elf-*`
# On installations using `multilib`, this will be `riscv64` even for compiling to 32-bit targets
TOOLCHAIN_PREFIX=riscv32-unknown-elf
#TOOLCHAIN_PREFIX=riscv32
ARCH=rv32i
#ARCH=rv32i_zicsr

# ---- Test patterns for project raven ----

.SUFFIXES:

PATTERN = dhry_1

hex:  ${PATTERN:=.hex}

dhry_1.elf: dhry_1.c dhry_2.c ../sections.lds ../crt0_vex.S
	#$(TOOLCHAIN_PATH)riscv32-unknown-elf-gcc -O0 -march=rv32i -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ ../start.s ../print_io.c $<
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-gcc -I../ -I../generated/ -O0 -mabi=ilp32 -march=$(ARCH) -DRISCV -DTIME -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ ../crt0_vex.S ../isr.c ../stub.c ../stdlib.c dhry_2.c $<
	${TOOLCHAIN_PATH}$(TOOLCHAIN_PREFIX)-objdump -D dhry_1.elf > dhry_1.lst

%.hex: %.elf
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-objcopy -O verilog $< $@
	sed -ie 's/@1000/@0000/g' $@

%.bin: %.elf
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-objcopy -O binary $< $@

client: client.c
	#gcc client.c -o client
	python3 ./client.py

flash: dhry_1.hex
	python3 ../util/caravel_hkflash.py dhry_1.hex

flash2: dhry_1.hex
	python3 ../util/caravel_flash.py dhry_1.hex

show_projectid:
	python3 ../util/caravel_projectid.py

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd

.PHONY: clean hex all flash

