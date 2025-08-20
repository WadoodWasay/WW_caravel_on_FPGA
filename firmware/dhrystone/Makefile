
#TOOLCHAIN_PATH=/usr/bin/
#TOOLCHAIN_PATH=/usr/local/bin
#TOOLCHAIN_PATH=/opt/riscv32imc/bin/
TOOLCHAIN_PATH=/opt/riscv32i/bin/
# TOOLCHAIN_PATH=/ef/apps/bin/

# Set the prefix for `riscvXX-unknown-elf-*`
# On installations using `multilib`, this will be `riscv64` even for compiling to 32-bit targets
TOOLCHAIN_PREFIX=riscv32-unknown-elf
#TOOLCHAIN_PREFIX=riscv32
#ARCH=rv32i
ARCH=rv32i_zicsr

# ---- Test patterns for dhrystone benchmarks on the Caravel VexRISC ----

.SUFFIXES:

PATTERN = dhrystone
OBJS = dhry_1.o dhry_2.o stdlib.o
SRCS = ../crt0_vex.S ../isr.c ../stub.c
CFLAGS = -DUSE_MYSTDLIB -ffreestanding -nostdlib -mabi=ilp32 -march=$(ARCH) -DRISCV -DTIME

hex:  ${PATTERN:=.hex}

%.o: %.c
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-gcc -I../ -I../generated/ -O0 -fpermissive -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-gcc -I../ -I../generated/ -O0 -c $(CFLAGS) $<

$(PATTERN).elf: $(OBJS) $(SRCS)
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-gcc -I../ -I../generated/ $(CFLAGS) -O0 -Wl,-Bstatic,-T,../sections.lds,--strip-debug -o $@ $(SRCS) $(OBJS) -lgcc -lc
	${TOOLCHAIN_PATH}$(TOOLCHAIN_PREFIX)-objdump -D $(PATTERN).elf > $(PATTERN).lst

%.hex: %.elf
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-objcopy -O verilog $< $@
	sed -ie 's/@1000/@0000/g' $@

%.bin: %.elf
	$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)-objcopy -O binary $< $@

client: client.c
	#gcc client.c -o client
	python3 ./client.py

flash: $(PATTERN).hex
	python3 ../util/caravel_hkflash.py $(PATTERN).hex

flash2: $(PATTERN).hex
	python3 ../util/caravel_flash.py $(PATTERN).hex

show_projectid:
	python3 ../util/caravel_projectid.py

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd

.PHONY: clean hex all flash

