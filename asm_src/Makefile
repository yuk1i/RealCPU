CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OBJCOPY=mipsel-linux-gnu-objcopy
OBJDUMP=mipsel-linux-gnu-objdump
STRIP=mipsel-linux-gnu-strip
# Configures for bin file

TEXT_START_AT=0x1000
DATA_START_AT=0x9000

CC_OPT=-frename-registers -fcombine-stack-adjustments -fcprop-registers
CC_FLAGS=-mabi=32 -mlong32 -mips32r6 -Werror -ffreestanding -mno-abicalls -fno-pic -mno-shared -O1 -fno-delayed-branch -fomit-frame-pointer -mcompact-branches=never -mno-llsc -msoft-float -static -fno-stack-protector
AS_FLAGS=-mips32r6 -mno-shared -msoft-float --fatal-warnings -O0
LD_FLAGS=--script linker.ld --no-compact-branches -static

BUILDDIR=tmp
SRCS=
OBJS=$(SRCS:%=$(BUILDDIR)/%.o)

.DEFAULT_GOAL := cputest

flash:
	@sudo python3 flash.py

system: SRCS=start system_uart utils/uart utils/seg7 io
system:
	@make SRCS="$(SRCS)" dump

rom:SRCS:=bootloader/rom bootloader/bootloader utils/uart io
rom:
	@make SRCS="$(SRCS)" objs
	@LD_FLAGS=
	@$(LD) --script rom.ld --no-compact-branches -nostdlib -static $(OBJS) -o tmp/rom.out
	@$(STRIP) -R .reginfo $(BUILDDIR)/rom.out
	@$(STRIP) -R .MIPS.abiflags $(BUILDDIR)/rom.out
	@$(STRIP) -R .gnu.attributes $(BUILDDIR)/rom.out
	@$(OBJCOPY) -O binary tmp/rom.out tmp/rom.bin
	@python3 convert.py tmp/rom.bin rom.coe

%:
	make SRCS="start $@ utils/uart utils/seg7 io" dump --no-print-directory
	@echo "\n[*] Compile and dump successfully\n"

objs: $(OBJS)
	@echo "done"

$(BUILDDIR)/%.o : %.c
	@echo "[CC] compile $<"
	@$(CC) $(CC_FLAGS) -c $< -o $@

$(BUILDDIR)/%.o : %.s
	@echo "[AS] assemble $<"
	@$(AS) $(AS_FLAGS) $< -o $@

link: $(OBJS)
	@echo "[LD] link"
	@$(LD) $(LD_FLAGS) $(OBJS) -L/usr/mipsel-linux-gnu/lib -lm -o $(BUILDDIR)/a.out
	@$(STRIP) -R .reginfo $(BUILDDIR)/a.out
	@$(STRIP) -R .MIPS.abiflags $(BUILDDIR)/a.out
	@$(STRIP) -R .gnu.attributes $(BUILDDIR)/a.out

dump: link
	@echo "[*]  dump coe"
	@$(OBJCOPY) --dump-section .text=tmp/text.bin tmp/a.out
	@$(OBJCOPY) --dump-section .data=tmp/data.bin tmp/a.out 
	@python3 convert.py tmp/text.bin text.coe $(TEXT_START_AT)
	@python3 convert.py tmp/data.bin data.coe $(DATA_START_AT) 16
	@$(OBJCOPY) -O binary tmp/a.out tmp/unified.bin
	@python3 convert.py tmp/unified.bin unified.coe 0x0 16


objdump:
	@$(OBJDUMP) -d -t tmp/a.out
	@echo "\n\n ==== .data section ===="
	@$(OBJDUMP) -s -j .data tmp/a.out

readelf:
	readelf -a a.out

clean:
	@echo "[*] clean done"
	@rm -f a.out *.o
	@rm -rf tmp/*
	@mkdir tmp/bootloader
	@mkdir tmp/utils
