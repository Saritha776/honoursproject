# ==============================================================================
# Makefile: RISC-V Bare-Metal C Compilation
# Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
# Target: RV32IMC Machine-Mode
# Output: neuroedge_test.elf, neuroedge_test.bin, program.hex (for simulation)
# ==============================================================================

CROSS_COMPILE ?= riscv32-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS  = -march=rv32imc -mabi=ilp32 -O2 -g -Wall -Wextra \
          -ffreestanding -nostdlib -fno-builtin \
          -I.

LDFLAGS = -T link.ld -nostdlib -Wl,--gc-sections

SRCS_C = main.c \
         hal_uart.c \
         hal_dma.c \
         hal_systolic.c \
         hal_spi.c \
         neural_ops.c

SRCS_ASM = crt0.S

OBJS = $(SRCS_ASM:.S=.o) $(SRCS_C:.c=.o)

all: neuroedge_test.elf neuroedge_test.hex neuroedge_test.bin neuroedge_test.dump

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

neuroedge_test.elf: $(OBJS) link.ld
	$(CC) $(CFLAGS) $(OBJS) $(LDFLAGS) -o $@

neuroedge_test.bin: neuroedge_test.elf
	$(OBJCOPY) -O binary $< $@

# Generate 32-bit hex words for Verilog $readmemh loading into Instruction SRAM
neuroedge_test.hex: neuroedge_test.bin
	python3 -c "import binascii; f=open('neuroedge_test.bin','rb').read(); [print(binascii.hexlify(f[i:i+4][::-1]).decode()) for i in range(0,len(f),4)]" > $@ 2>/dev/null || \
	xxd -p -c 4 $< | awk '{print substr($$0,7,2) substr($$0,5,2) substr($$0,3,2) substr($$0,1,2)}' > $@

neuroedge_test.dump: neuroedge_test.elf
	$(OBJDUMP) -D $< > $@

clean:
	rm -f *.o *.elf *.bin *.hex *.dump

.PHONY: all clean
