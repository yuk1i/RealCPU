CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OBJCOPY=mipsel-linux-gnu-objcopy
OBJDUMP=mipsel-linux-gnu-objdump
STRIP=mipsel-linux-gnu-strip
# Configures for bin file

TEXT_START_AT=0x0100
DATA_START_AT=0x1000

CC_FLAGS=-mips32r6 -Werror -O0 -fno-pic -mcompact-branches=never -mno-llsc -msoft-float -mno-abicalls
AS_FLAGS=-mips32r6 --alternate -mgp32 -g -call_nonpic -non_shared -mno-ginv -msoft-float --fatal-warnings -O0
LD_FLAGS=--script linker.ld --no-compact-branches -nostdlib

BUILDDIR=tmp
SRCS=
OBJS=$(SRCS:%=$(BUILDDIR)/%.o)


.DEFAULT_GOAL := cputest

system: SRCS="system start"
system:
	make SRCS=$(SRCS) dump

rom:
	@LD_FLAGS=
	@$(AS) $(AS_FLAGS) bootloader/rom.s -o tmp/rom.o
	@$(CC) $(CC_FLAGS) -c bootloader/bootloader.c -o tmp/bootloader.o
	@$(LD) --Ttext 0xFFFFE000 -Tdata 0xFFFFFA00 --no-compact-branches -nostdlib --entry __rom_start tmp/rom.o tmp/bootloader.o -o tmp/rom.out
	@mipsel-linux-gnu-strip -R .reginfo $(BUILDDIR)/rom.out
	@mipsel-linux-gnu-strip -R .MIPS.abiflags $(BUILDDIR)/rom.out
	@mipsel-linux-gnu-strip -R .gnu.attributes $(BUILDDIR)/rom.out
	@$(OBJCOPY) -O binary tmp/rom.out tmp/rom.bin
	@python3 convert.py tmp/rom.bin rom.coe

%:
	make SRCS=$@ dump --no-print-directory
	@echo "\n[*] Compile and dump successfully\n"

$(BUILDDIR)/%.o : %.c
	@echo "[CC] compile $<"
	@$(CC) $(CC_FLAGS) -c $< -o $@

$(BUILDDIR)/%.o : %.s
	@echo "[AS] assemble $<"
	@$(AS) $(AS_FLAGS) $< -o $@

link: $(OBJS)
	@echo "[LD] link"
	@$(LD) $(LD_FLAGS) $(OBJS) -o $(BUILDDIR)/a.out
	@mipsel-linux-gnu-strip -R .reginfo $(BUILDDIR)/a.out
	@mipsel-linux-gnu-strip -R .MIPS.abiflags $(BUILDDIR)/a.out
	@mipsel-linux-gnu-strip -R .gnu.attributes $(BUILDDIR)/a.out

dump: link
	@echo "[*]  dump coe"
	@rm -f *.coe tmp/*.bin
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
	@rm -f a.out *.o tmp/*.bin *.coe tmp/*.o tmp/*.out
